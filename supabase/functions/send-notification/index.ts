// Edge Function: send-notification
//
// Pushes an already-stored notification to the recipient's registered devices
// via FCM HTTP v1. The in-app inbox row is inserted by the client (RLS-guarded);
// this function is push-only and best-effort.
//
// Auth: caller must be an approved admin, or hold the permission matching the
// send's shape — `notifications.send` for one person,
// `notifications.broadcast_module` for a file topic,
// `notifications.broadcast_all` for the everyone topic.
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

    // Two shapes of send:
    //
    //   { recipient_id } — one person, fanned out over their devices here.
    //   { topic }        — everyone subscribed to it, fanned out by Google.
    //
    // The second is the one that scales. A file with five hundred members is a
    // single HTTP call instead of five hundred, and the function does not have
    // to hold the token list at all.
    // `data` is what the notification is ABOUT, and it is the only reason a tap
    // on the phone's own tray can go anywhere. Without it the push carries a
    // sentence and nothing else: the app opens where it was left, and "تم
    // إسنادك إلى ملف تشغيلي" leads nowhere.
    const { recipient_id, topic, title, body, data } = (await req.json()) ?? {};
    if (!title || (!recipient_id && !topic)) {
      return json({ error: 'title and one of recipient_id / topic are required' }, 400);
    }

    // The shape of the send decides which permission it needs — the same three
    // the database enforces on the inbox rows (0073): one person, one file's
    // topic, or the everyone topic.
    const requiredCode = recipient_id
      ? 'notifications.send'
      : topic === 'all'
        ? 'notifications.broadcast_all'
        : 'notifications.broadcast_module';

    const admin = createClient(url, serviceKey);
    // `has_permission` reads auth.uid(), which a service-role call does not
    // carry — so the grant is read directly, the way admin-delete-user does.
    const { data: prof } = await admin
      .from('profiles')
      .select('is_admin, account_status, is_suspended')
      .eq('id', callerId)
      .single();
    const active =
      prof?.account_status === 'approved' && !prof?.is_suspended;
    if (!active) return json({ error: 'forbidden' }, 403);
    if (!prof?.is_admin) {
      const { data: grant } = await admin
        .from('user_permissions')
        .select('permission_id, permissions!inner(code)')
        .eq('user_id', callerId)
        .eq('permissions.code', requiredCode)
        .maybeSingle();
      if (!grant) return json({ error: 'forbidden' }, 403);
    }
    // A topic is never taken verbatim. This app has exactly two shapes of
    // topic — `all`, and `module_<uuid>` — and anything else is refused, so a
    // grant-holder cannot use this function to push to an arbitrary FCM topic
    // string. A module topic must also name a module that exists: the DB rule
    // (0073) is that `broadcast_module` may address any file, but it has to be
    // a file, not a guess.
    //
    // Note on confidentiality: FCM topic subscription is client-controlled, so
    // a topic push is a megaphone, not an envelope — anything secret belongs
    // in the RLS-guarded inbox row, not in the push's title or body.
    if (topic && topic !== 'all') {
      const m = /^module_([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})$/.exec(
        topic,
      );
      if (!m) return json({ error: 'invalid topic' }, 400);
      const { data: module } = await admin
        .from('modules')
        .select('id')
        .eq('id', m[1])
        .maybeSingle();
      if (!module) return json({ error: 'unknown module' }, 400);
    }

    if (!saRaw) {
      // Push not configured — the in-app notification still exists.
      return json({ pushed: 0, note: 'FIREBASE_SERVICE_ACCOUNT not set' });
    }
    const sa = JSON.parse(saRaw);

    const accessToken = await getAccessToken(sa);
    const endpoint = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

    // FCM will only carry strings here, and rejects the whole message if it is
    // handed anything else — so a nested value is dropped rather than allowed
    // to lose the notification it was riding on. Nothing this app targets with
    // is nested; if that changes, this is the line to widen.
    const payload = (() => {
      if (!data || typeof data !== 'object') return null;
      const out: Record<string, string> = {};
      for (const [k, v] of Object.entries(data)) {
        if (v === null || v === undefined) continue;
        if (typeof v === 'object') continue;
        out[k] = String(v);
      }
      return Object.keys(out).length ? out : null;
    })();

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
            ...(payload ? { data: payload } : {}),
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
