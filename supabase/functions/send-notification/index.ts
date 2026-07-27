// Edge Function: send-notification
//
// Pushes an already-stored notification to the recipient's registered devices
// via FCM HTTP v1. The in-app inbox row is inserted by the client (RLS-guarded);
// this function is push-only and best-effort.
//
// Auth: caller must be an approved admin or hold `notifications.send`.
//
// Secret required (set once):
//   supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat firebase/hajjoperations-firebase-adminsdk-*.json)"
//
// Deploy: supabase functions deploy send-notification

import { createClient } from 'jsr:@supabase/supabase-js@2';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function b64url(bytes: Uint8Array): string {
  let s = btoa(String.fromCharCode(...bytes));
  return s.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function b64urlStr(str: string): string {
  return b64url(new TextEncoder().encode(str));
}

function pemToDer(pem: string): Uint8Array {
  const body = pem
    .replace(/-----BEGIN [^-]+-----/, '')
    .replace(/-----END [^-]+-----/, '')
    .replace(/\s+/g, '');
  const bin = atob(body);
  const der = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) der[i] = bin.charCodeAt(i);
  return der;
}

async function getAccessToken(sa: any): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claim = {
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };
  const unsigned = `${b64urlStr(JSON.stringify(header))}.${b64urlStr(JSON.stringify(claim))}`;

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToDer(sa.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${b64url(new Uint8Array(sig))}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body:
      'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=' + jwt,
  });
  const j = await res.json();
  if (!j.access_token) throw new Error('token exchange failed: ' + JSON.stringify(j));
  return j.access_token;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  const url = Deno.env.get('SUPABASE_URL')!;
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const saRaw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');

  const json = (b: unknown, status = 200) =>
    new Response(JSON.stringify(b), {
      status,
      headers: { ...cors, 'Content-Type': 'application/json' },
    });

  try {
    // Authorize the caller.
    const caller = createClient(url, anonKey, {
      global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
    });
    const { data: u } = await caller.auth.getUser();
    const callerId = u?.user?.id;
    if (!callerId) return json({ error: 'unauthorized' }, 401);

    const admin = createClient(url, serviceKey);
    const { data: allowed } = await admin.rpc('has_permission', {
      p_code: 'notifications.send',
    });
    // has_permission runs as the definer using the caller context only when
    // invoked with their JWT; here we re-check via a direct query instead.
    const { data: prof } = await admin
      .from('profiles')
      .select('is_admin, account_status, is_suspended')
      .eq('id', callerId)
      .single();
    const isAdmin =
      prof?.is_admin && prof?.account_status === 'approved' && !prof?.is_suspended;
    if (!isAdmin && allowed !== true) return json({ error: 'forbidden' }, 403);

    // Two shapes of send:
    //
    //   { recipient_id } — one person, fanned out over their devices here.
    //   { topic }        — everyone subscribed to it, fanned out by Google.
    //
    // The second is the one that scales. A file with five hundred members is a
    // single HTTP call instead of five hundred, and the function does not have
    // to hold the token list at all.
    const { recipient_id, topic, title, body } = (await req.json()) ?? {};
    if (!title || (!recipient_id && !topic)) {
      return json({ error: 'title and one of recipient_id / topic are required' }, 400);
    }
    // A topic name reaches FCM verbatim, so it is checked rather than trusted.
    if (topic && !/^[a-zA-Z0-9\-_.~%]{1,900}$/.test(topic)) {
      return json({ error: 'invalid topic' }, 400);
    }

    if (!saRaw) {
      // Push not configured — the in-app notification still exists.
      return json({ pushed: 0, note: 'FIREBASE_SERVICE_ACCOUNT not set' });
    }
    const sa = JSON.parse(saRaw);

    const accessToken = await getAccessToken(sa);
    const endpoint = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

    const send = async (target: Record<string, unknown>) => {
      const r = await fetch(endpoint, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            ...target,
            notification: { title, body: body ?? '' },
            android: { priority: 'high' },
          },
        }),
      });
      return r.ok;
    };

    if (topic) {
      const ok = await send({ topic });
      return json({ pushed: ok ? 1 : 0, topic });
    }

    const { data: tokens } = await admin
      .from('device_tokens')
      .select('token')
      .eq('user_id', recipient_id);
    if (!tokens || tokens.length === 0) return json({ pushed: 0 });

    let pushed = 0;
    for (const t of tokens) {
      if (await send({ token: t.token })) pushed++;
    }
    return json({ pushed });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
