# مواصفات REST API — خطة الاستبدال الكامل لـ Supabase

> **الغرض:** هذا المستند هو المرجع التعاقدي بين تطبيق Flutter وفريق الـ Backend في حال
> الانتقال من Supabase إلى REST API مخصص. تم استخراجه من **الكود الفعلي** للتطبيق
> (كل استدعاء `supabase.from / rpc / storage / functions / auth` موجود في المشروع)
> ومن ملفات الـ migrations (`supabase/migrations/0001 → 0073`).
>
> **تاريخ الإعداد:** 2026-07-31 — فرع `operational-files`.
> **آخر تحديث:** 2026-08-04 — **التفقّد الميداني** (migration 0087): جدول
> `node_check_ins` وRPC للتسجيل وأخرى للوحة الحضور. دليلان — رمز ملصق على المكان
> وموقع الهاتف — **والمسافة تُحسب في الخادم**، والتسجيل المشكوك فيه يُوسم ولا
> يُرفض. يمرّ بطابور §27، والموقع يُلتقط لحظة الضغط لا لحظة الإرسال. §30.
> وقبله 2026-08-04 — **التصعيد التلقائي** (migration 0086): أول شيء في
> هذا النظام يراقب **ما لم يحدث**. مرور يومي بـ pg_cron يجد من استُحقّ عليه تقرير
> دوري ولم يرفعه، فيبلّغه، ثم يبلّغ من فوقه في اليوم التالي عبر سلّم مأخوذ من
> مستويات الملف نفسها. جدول `report_misses`، وأربع دوال، ومهمة مجدولة — §29،
> **وفيه أن `module_report_period` صارت المصدر الوحيد لتعريف الفترة**.
> وقبله 2026-08-04 — **تصدير البيانات**: شاشة واحدة في الإعدادات تُخرج
> تسع مجموعات (الموظفون، المشاركون، الملفات، أعضاؤها، مهامها، البيانات المرجعية،
> التقارير، الشكاوى، التقييمات) كـ CSV أو PDF، بأعمدة يختارها المُصدِّر. **لا
> endpoints جديدة** — يقرأ عبر ما هو موثّق أصلاً — والالتزام الوحيد على الخادم أن
> يبقى تضييق `scope=all` وحجب اسم المشتكي عاملَين، §28.
> وقبله 2026-08-04 — **العمل دون اتصال**: طابور إرسال على الجهاز
> يحفظ الكتابتين الميدانيتين (حالة المهمة، تقرير الملف) مع مرفقاتهما حين تسقط
> الشبكة، ويرسلهما حين تعود. **لا جداول ولا endpoints جديدة**، لكن الشرط الذي
> يفرضه على الخادم جوهري: كل عملية ميدانية يجب أن تحتمل إعادة تنفيذها كاملةً —
> §27، وفيه ثغرة تكرار مرفقات معروفة يُنصح بإغلاقها بقيد تفرّد. ومعه حدود حجم
> المرفقات (§19.2.1) — 25MB على العميل، و`413` بكود واضح من الخادم.
> وقبله 2026-08-04 — نظام التقييم (migration 0084): نموذج تكتبه
> الإدارة بمراحل وأسئلة وعلامات، وتقييم واحد يُفتح باسم مُقيِّم واحد عن جهة
> واحدة. ستة جداول جديدة (`evaluation_templates`, `evaluation_stages`,
> `evaluation_questions`, `evaluation_options`, `evaluations`,
> `evaluation_answers`)، قسم صلاحيات `evaluations` بأربعة أكواد **ليس فيها
> كودٌ للتعبئة** — التقييم يصل بالاسم لا بالصلاحية — وسرّية بنيوية تمنع
> المُقيَّم من معرفة من قيَّمه، وتجميد نصّ السؤال وعلامته داخل كل إجابة حتى لا
> يتغيّر معنى تقييمٍ معتمَد بتعديل نموذجه. §26، والتزامات الخادم في §26.10.
> **لا علاقة لهذا بتقييم النجوم داخل الملفات التشغيلية (0059، §13) — ذاك يبقى
> كما هو ولم يُمسّ.** وقبلها 2026-08-03 — إعادة تصميم نظام المهام (migration 0083): المهمة
> لم تعد مرتبطة بالمستخدم افتراضياً، بل بأحد ثلاثة نطاقات — الملف، الدور،
> الشخص — وصار لها **حالة** لم تكن موجودة قط. ثلاثة جداول جديدة
> (`module_tasks`, `module_task_status`, `module_task_attachments`)، وحالة
> **لكل موقع** لمهام الدور، وصلاحية `modules.tasks`، و RPCs
> (`module_task_board`, `set_module_task_state`)، وتوسعة سياسات دلو `modules`.
> §25، والتزامات الخادم في §25.8. وقبلها 2026-08-02 — إضافة الشكاوى (migrations 0079 و 0080): ثلاثة
> جداول، دلو تخزين سادس، قسم صلاحيات `complaints` بخمسة أكواد، وقاعدة تُوقف
> حساب موظف تلقائياً عند بلوغ ثلاثة مشتكين مختلفين — مع سرّية بنيوية تمنع
> المشتكى عليه من معرفة من اشتكى. §24، والتزامات الخادم في §24.9.
> وقبلها 2026-08-01 — إضافة سجل الأحداث (migration 0077): جدول
> `audit_log` مع trigger عام على كل الجداول، صلاحية `audit.view`، ثلاث RPCs
> (`audit_events`, `audit_actors`, `log_auth_event`)، وأسطر توثيق ذاتية في
> الـ Edge Functions الأربع — §23. وقبلها إصلاحات الجولة الشاملة: حفظ التقرير
> صار RPC واحدة (`save_report`, migration 0074)، سقف لقائمتي الوارد (100)
> والتقارير (200) مع إسقاط `data` من قائمة التقارير، تحقق الخادم من صيغة
> الـ topic ووجود الملف، واشتقاق `gregorian_label` من امتداد السنة الهجرية.

---

## جدول المحتويات

1. [الاصطلاحات العامة](#1-الاصطلاحات-العامة)
2. [المصادقة Authentication](#2-المصادقة-authentication)
3. [الملف الشخصي والتسجيل](#3-الملف-الشخصي-والتسجيل)
4. [الصلاحيات Permissions](#4-الصلاحيات-permissions)
5. [الموظفون Employees](#5-الموظفون-employees)
6. [الموافقات Approvals](#6-الموافقات-approvals)
7. [المواسم Seasons](#7-المواسم-seasons)
8. [أنواع الملفات التشغيلية Module Types](#8-أنواع-الملفات-التشغيلية-module-types)
9. [الملفات التشغيلية Modules](#9-الملفات-التشغيلية-modules)
10. [شجرة الملف (القطاعات والأبراج) Nodes](#10-شجرة-الملف-nodes)
11. [أعضاء الملف والمهام Members & Tasks](#11-أعضاء-الملف-والمهام)
12. [تقارير الملف التشغيلي Module Reports](#12-تقارير-الملف-التشغيلي)
13. [التقييمات Ratings](#13-التقييمات-ratings)
14. [البيانات المرجعية Master Data](#14-البيانات-المرجعية-master-data)
15. [القرارات Decisions (الجداول باسم `reports`)](#15-القرارات-decisions-الجداول-باسم-reports)
16. [الإشعارات Notifications](#16-الإشعارات-notifications)
17. [أجهزة الدفع Push / Device Tokens](#17-أجهزة-الدفع-push--device-tokens)
18. [لوحة المعلومات Dashboard](#18-لوحة-المعلومات-dashboard)
19. [الملفات والتخزين Storage](#19-الملفات-والتخزين-storage)
20. [البث اللحظي Realtime](#20-البث-اللحظي-realtime)
21. [منطق الخادم الإلزامي (بديل RLS / Triggers)](#21-منطق-الخادم-الإلزامي)
22. [قاموس الأخطاء](#22-قاموس-الأخطاء)
23. [سجل الأحداث Audit Log](#23-سجل-الأحداث-audit-log)
24. [الشكاوى Complaints](#24-الشكاوى-complaints)
25. [المهام Tasks — الملف والدور والشخص](#25-المهام-tasks--الملف-والدور-والشخص)
26. [التقييم Evaluations — النموذج والتكليف](#26-التقييم-evaluations--النموذج-والتكليف)
27. [طابور الإرسال Outbox — التزامات الخادم تجاه إعادة الإرسال](#27-طابور-الإرسال-outbox--التزامات-الخادم-تجاه-إعادة-الإرسال)
28. [تصدير البيانات Export — لا endpoints، ولكن التزام واحد](#28-تصدير-البيانات-export--لا-endpoints-ولكن-التزام-واحد)
29. [التصعيد التلقائي — ملاحظة ما لم يحدث](#29-التصعيد-التلقائي--ملاحظة-ما-لم-يحدث-migration-0086)
30. [البلاغ العاجل Incidents](#30-البلاغ-العاجل-incidents-migration-0088)
31. [خريطة الموسم Season map](#31-خريطة-الموسم-season-map-migrations-0090--0093)
30. [التفقّد الميداني Check-in](#30-التفقد-الميداني-check-in-migrations-0087--0094)

---

## 1. الاصطلاحات العامة

### 1.1 الأساسيات

| البند              | القيمة                                                                                                                                             |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| Base URL           | `https://api.example.com/v1` (يحدده الـ backend)                                                                                                   |
| صيغة التبادل       | JSON — `Content-Type: application/json; charset=utf-8`                                                                                             |
| رفع الملفات        | `multipart/form-data`                                                                                                                              |
| المصادقة           | `Authorization: Bearer <access_token>` (JWT) على **كل** المسارات ما عدا التسجيل والدخول                                                            |
| التواريخ الزمنية   | ISO-8601 UTC — مثال `2026-07-31T09:15:00Z`                                                                                                         |
| التواريخ اليومية   | `YYYY-MM-DD` (حقول مثل `starts_on`, `date_of_birth`)                                                                                               |
| المعرّفات          | UUID v4 نصي                                                                                                                                        |
| الترقيم Pagination | `?limit=<int>&offset=<int>` حيث تُذكر                                                                                                              |
| اللغة              | كل الكيانات المعرّبة تحمل حقلين: `name_ar` (إلزامي) و `name_en` (اختياري nullable) — **الاختيار بين اللغتين يتم في التطبيق، فلا يُرسل header لغة** |

### 1.2 الصيغة الموحّدة للخطأ

```json
{
  "error": {
    "code": "forbidden",
    "message": "You do not hold modules.edit"
  }
}
```

| HTTP | متى                                                                  |
| ---- | -------------------------------------------------------------------- |
| 400  | جسم طلب ناقص/غير صالح، أو خرق قاعدة عمل (مثل حذف عنصر مرجعي مستخدَم) |
| 401  | لا توكن / توكن منتهٍ                                                 |
| 403  | مصادَق لكن لا يملك الصلاحية، أو الحساب موقوف/غير معتمد               |
| 404  | المورد غير موجود **أو غير مرئي للطالب** (لا نفرّق بينهما أمنياً)     |
| 409  | تعارض فريد (unique constraint)                                       |
| 422  | فشل تحقق حقول                                                        |

### 1.3 نموذج الصلاحيات (أساس كل شيء)

كل حساب إما `is_admin = true` (يملك كل شيء) أو يحمل مجموعة أكواد صلاحيات.
**القاعدة المعتمدة في التطبيق:** `can(code) = is_admin || permissions.contains(code)`.

كتالوج الأكواد الكامل (مطابق لجدول `permissions` — migration 0073):

| القسم             | الأكواد                                                                                                                                                     |
| ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| الموظفون          | `employees.view` `employees.create` `employees.edit` `employees.delete` `employees.suspend` `employees.external` `employees.documents` `employees.password` `employees.email` |
| الموافقات         | `approvals.view` `approvals.decide`                                                                                                                         |
| المواسم           | `seasons.view` `seasons.switch` `seasons.participants_view` `seasons.participants_manage`                                                                   |
| الملفات التشغيلية | `modules.view_all` `modules.create` `modules.edit` `modules.delete` `modules.activate` `modules.members` `modules.reports`                                  |
| البيانات المرجعية | `reference.view` `reference.edit` `reference.delete` `reference.import`                                                                                     |
| التقارير          | `reports.view_all` `reports.create` `reports.edit` `reports.delete` `reports.publish`                                                                       |
| الإشعارات         | `notifications.send` `notifications.broadcast_module` `notifications.broadcast_all`                                                                         |
| الصلاحيات         | `permissions.view` `permissions.manage`                                                                                                                     |
| سجل الأحداث       | `audit.view`                                                                                                                                                |
| الشكاوى           | `complaints.view` `complaints.reply` `complaints.lock` `complaints.dismiss` `complaints.delete`                                                             |

**تقديم شكوى ليس له كود، عمداً**: أي حساب معتمد يقدّم. سجلٌّ لما يقع خطأً لا
يكتبه إلا بعضُ الناس ليس سجلاً لما يقع خطأً (§24).

توجد **متطلبات مسبقة** بين الصلاحيات (جدول `permission_prerequisites`): لا يجوز منح
صلاحية دون أساسها (مثال: `modules.members` تتطلب `employees.view`)، وسحب الأساس
يسحب توابعه تلقائياً (§21.4). ومنها واحدة تستحق الانتباه:
`complaints.dismiss` تتطلب `employees.suspend`، لأن رفض شكوى قد يرفع إيقافاً
آلياً — فمن يرفض يمسك مفتاح الإيقاف سواء قالت ورقة المنح ذلك أم لا.

### 1.4 حالات الحساب

`account_status`: `incomplete` → `pending` → `approved` | `rejected`، مع علم مستقل
`is_suspended`. **الحساب الفعّال = approved && !is_suspended** — وهو الشرط الأدنى
لأي مسار غير مسارات المصادقة/التسجيل.

### 1.5 الكيان `Profile` (الاستجابة القياسية للموظف)

يُعاد بهذا الشكل في كل مكان يُذكر فيه "Profile object":

```json
{
  "id": "uuid",
  "email": "user@example.com",
  "first_name": "أحمد",
  "father_name": "محمد",
  "surname": "الخطيب",
  "photo_url": "https://cdn.example.com/avatars/uuid/photo.jpg",
  "job_title_id": "uuid",
  "job_title": { "name_ar": "طبيب", "name_en": "Physician" },
  "gender": "male",
  "mission_type_id": "uuid",
  "mission_type": { "name_ar": "البعثة الطبية", "name_en": "Medical mission" },
  "date_of_birth": "1980-05-14",
  "city_id": "uuid",
  "city": { "name_ar": "دمشق", "name_en": "Damascus" },
  "phone_sy": "+963...",
  "phone_sa": "+966...",
  "is_admin": false,
  "is_external": false,
  "external_organization": null,
  "external_title": null,
  "is_suspended": false,
  "account_status": "approved",
  "rejection_reason": null,
  "passport_image_url": "documents/uuid/passport.jpg",
  "visa_image_url": null,
  "nusuk_card_image_url": null,
  "created_at": "2026-01-01T00:00:00Z",
  "updated_at": "2026-01-01T00:00:00Z"
}
```

> ملاحظة: `photo_url` رابط عام كامل (bucket avatars عام)، بينما حقول الوثائق
> (`passport_image_url`…) هي **مسارات تخزين** تُفتح عبر روابط موقّعة (§19).

---

## 2. المصادقة Authentication

Supabase Auth هو مزوّد الهوية الحالي. البديل يجب أن يوفّر: JWT قصير العمر +
Refresh Token **متغيّر عند كل تجديد** (rotation) — التطبيق يعتمد على ذلك حرفياً
في ميزة "تبديل الحسابات" حيث يخزّن refresh token لكل حساب في keystore الجهاز.

> الجلسة **الأساسية** أيضاً تُخزَّن في keystore الجهاز (`SecureSessionStorage`)
> لا في SharedPreferences، والنسخ الاحتياطي لأندرويد معطَّل (`allowBackup=false`)
> — أي عميل بديل يجب أن يحافظ على المستوى نفسه.

### 2.1 إنشاء حساب

```
POST /auth/register
```

**Request:**

```json
{ "email": "user@example.com", "password": "secret123" }
```

**Response 201:**

```json
{
  "user": { "id": "uuid", "email": "user@example.com" },
  "access_token": "jwt",
  "refresh_token": "opaque",
  "expires_in": 3600
}
```

**قواعد إلزامية على الخادم:**

- إنشاء صف `profile` تلقائياً بحالة `incomplete` (يقوم به حالياً trigger `handle_new_user`).
- تطبيع البريد وقصّ الفراغات.
- أخطاء: `409 email_exists`، `422 weak_password`.

### 2.2 الدخول بالبريد وكلمة السر

```
POST /auth/login
```

**Request:** `{ "email": "...", "password": "..." }`
**Response 200:** نفس شكل 2.1.
**أخطاء:** `400 invalid_credentials`.

### 2.3 الدخول عبر Google

التطبيق يحصل على **Google ID Token** محلياً (google_sign_in) ثم يسلّمه للخادم.

```
POST /auth/google
```

**Request:** `{ "id_token": "<google id_token (JWT)>" }`

**متطلبات الخادم:** التحقق من التوقيع، ومن أن `aud` يساوي
`GOOGLE_WEB_CLIENT_ID` المتفق عليه، ثم إيجاد/إنشاء المستخدم بالبريد الوارد
(مع صف profile كما في 2.1 إن كان جديداً).

**Response 200:** نفس شكل 2.1.

### 2.4 تجديد الجلسة (حرِج — عليه تُبنى ميزة تبديل الحسابات)

```
POST /auth/refresh
```

**Request:** `{ "refresh_token": "opaque" }`

**Response 200:** نفس شكل 2.1 مع **refresh_token جديد** (القديم يُبطل بعد
نافذة سماح قصيرة لإعادة الاستخدام).

**ملاحظات سلوكية يعتمدها التطبيق:**

- هذا المسار نفسه هو ما يستخدمه "التبديل إلى حساب محفوظ": التطبيق يرسل
  refresh token الحساب الآخر ويستبدل الجلسة كاملة، **دون** تسجيل خروج الحساب الحالي.
- refresh token المرفوض (مُلغى أو منتهٍ) ⇒ `401 invalid_refresh_token`،
  وعندها يحذف التطبيق الحساب من قائمة المحفوظين.

### 2.5 تسجيل الخروج

```
POST /auth/logout
```

**Request:** `{ "scope": "global" | "local" }`

- `global`: إبطال كل جلسات المستخدم وكل refresh tokens.
- `local`: إبطال الجلسة الحالية فقط.

**Response:** `204`.

### 2.6 تغيير كلمة سر المستخدم نفسه

```
PATCH /auth/password
```

**Request:** `{ "new_password": "..." }` — **Response:** `204`.
**أخطاء:** `422 weak_password`.

### 2.7 تغيير البريد الإلكتروني للمستخدم نفسه

في التطبيق الحالي يمر عبر Edge Function `admin-set-email` نفسها (المستخدم يمرر
معرّفه هو): **لا تُرسل رسائل تأكيد** لأي من العنوانين — البعثة تسلّم الحسابات
يداً بيد، والعنوان يتغيّر فوراً ويبقى تسجيل الدخول قائماً.

```
PATCH /auth/email
```

**Request:** `{ "email": "new@example.com" }` — **Response:** `200 { "email" }`.

**قواعد إلزامية:**

- متاح لكل حساب **مقبول وغير موقوف** (لا يحتاج أي صلاحية).
- `400 email_invalid` — صيغة غير صالحة.
- `400 email_taken` — البريد مستخدم من حساب آخر (فرادة `auth.users`).
- البريد يُكتب مؤكَّداً، وعمود `profiles.email` مرآة تتبعه عبر trigger
  (migration 0026).

---

## 3. الملف الشخصي والتسجيل

### 3.1 ملفي الشخصي

```
GET /me/profile
```

**Response 200:** Profile object (§1.5).
**Response 404:** الحساب موجود لكن الصف غير جاهز بعد — التطبيق يعامله كـ `incomplete`.

### 3.2 صلاحياتي

بديل RPC `my_permissions`. يُستدعى بعد كل تحميل جلسة لحساب approved غير أدمن.

```
GET /me/permissions
```

**Response 200:**

```json
{ "permissions": ["modules.view_all", "reports.create"] }
```

### 3.3 تعديل ملفي (حساب معتمد)

```
PUT /me/profile
```

**Request:** (حقول الصور تُرسل **فقط** إذا تغيّرت — إرسالها null يعني "لا تغيير"،
لأن التطبيق لا يرسلها أصلاً إن لم تتبدل):

```json
{
  "first_name": "أحمد",
  "father_name": "محمد",
  "surname": "الخطيب",
  "job_title_id": "uuid",
  "gender": "male",
  "date_of_birth": "1980-05-14",
  "mission_type_id": "uuid",
  "phone_sy": "+963...",
  "phone_sa": null,
  "city_id": "uuid",
  "photo_url": "https://...",
  "passport_image_url": "documents/uuid/passport.jpg",
  "visa_image_url": null,
  "nusuk_card_image_url": null
}
```

**Response 200:** Profile object محدّث.
**حماية إلزامية:** تجاهل/رفض أي محاولة لتعديل الأعمدة المحمية
`is_admin`, `is_external`, `account_status`, `is_suspended`, `email` (§21.2).

### 3.4 إرسال الملف للاعتماد (التسجيل الأولي)

نفس حمولة 3.3 لكن `photo_url` **إلزامي**، والخادم يضبط
`account_status = "pending"` ضمن نفس العملية.

```
POST /me/profile/submit
```

**Response 200:** Profile object وحالته `pending`.

### 3.5 القوائم المتاحة قبل الاعتماد

الحسابات غير المعتمدة تحتاجها لتعبئة نموذج التسجيل — **يكفي فيها توكن صالح
دون شرط approved**:

```
GET /reference/syrian-cities
```

**Response:** `[{ "id": "uuid", "name_ar": "دمشق", "name_en": "Damascus" }]`
(المفعّلة فقط، مرتبة بـ `sort_order`).

```
GET /reference/job-titles
GET /reference/mission-types
```

**Response:** `[{ "id": "uuid", "name_ar": "طبيب", "name_en": "Physician" }]`
(المفعّلة فقط، مرتبة بـ `sort_order`).

> الوصف الوظيفي ونوع البعثة قائمتان مرجعيتان كاملتان (`job_titles`,
> `mission_types`) يديرهما المشرف من §14 كبقية القوائم — لا جدول مستقل ولا
> enum. الثلاث المتاحة قبل الاعتماد هي `syrian_cities`, `job_titles`,
> `mission_types`.

---

## 4. الصلاحيات Permissions

**صلاحية الوصول:** `permissions.view` للقراءة، `permissions.manage` للمنح/السحب.

### 4.1 الموظفون القابلون للمنح

```
GET /permissions/employees
```

حسابات `approved` وغير أدمن (الأدمن يملك كل شيء). **Response:** `[Profile]` مرتبة بالاسم الأول.

### 4.2 كتالوج الصلاحيات

```
GET /permissions/catalog
```

**Response:**

```json
[
  {
    "id": "uuid",
    "code": "employees.view",
    "section": "employees",
    "name_ar": "عرض الموظفين",
    "name_en": "View employees",
    "sort_order": 10
  }
]
```

### 4.3 المتطلبات المسبقة

```
GET /permissions/prerequisites
```

**Response:**

```json
{ "prerequisites": [{ "permission_id": "uuid", "requires_id": "uuid" }] }
```

### 4.4 صلاحيات مستخدم محدد

```
GET /users/{userId}/permissions
```

**Response:** `{ "permission_ids": ["uuid", "uuid"] }`

### 4.5 منح

```
POST /users/{userId}/permissions
```

**Request:** `{ "permission_id": "uuid" }` — **Response:** `201`.
الخادم يسجّل `granted_by` من التوكن، ويرفض `400 missing_prerequisite`
إذا كان أساس الصلاحية غير ممنوح (§21.4).

### 4.6 سحب

```
DELETE /users/{userId}/permissions/{permissionId}
```

**Response:** `204`. السحب **يتسلسل** على التوابع تلقائياً (§21.4).

---

## 5. الموظفون Employees

### 5.1 إنشاء حساب موظف (بديل Edge Function `admin-create-user`)

**الصلاحية:** أدمن فقط (فحص فعلي في الدالة الحالية: approved + غير موقوف + is_admin).

```
POST /admin/employees
```

**Request:**

```json
{
  "email": "new@example.com",
  "password": "secret123",
  "first_name": "أحمد",
  "father_name": "محمد",
  "surname": "الخطيب",
  "job_title_id": "uuid",
  "gender": "male",
  "mission_type_id": "uuid",
  "phone_sy": "+963...",
  "phone_sa": null,
  "date_of_birth": "1980-05-14",
  "is_external": false,
  "external_organization": null,
  "external_title": null
}
```

**Response 201:** `{ "id": "uuid" }`

**سلوك إلزامي:** إنشاء مستخدم Auth بالبريد **مؤكَّداً مسبقاً**، ثم تعبئة الـ profile
وضبط `account_status = "approved"` مباشرة. حقلا external يُحفظان فقط إذا
`is_external = true`.
**أخطاء:** `401 unauthorized`، `403 forbidden`، `400` مع رسالة (بريد مكرر…).

### 5.2 الكادر الدائم

```
GET /employees/permanent
```

بديل view `permanent_employees`: **داخلي (غير external) + approved**.
**Response:** `[Profile]` مرتبة بالاسم الأول.

### 5.3 المشاركون الخارجيون

```
GET /employees/external?season_id={uuid}
```

- بدون `season_id`: كل approved الذين `is_external = true`.
- مع `season_id`: الخارجيون **المشاركون الفعليون** في ذلك الموسم
  (عبر `season_participants` بحالة `active`).

**Response:** `[Profile]`.

### 5.4 موظف واحد

```
GET /employees/{profileId}
```

**Response:** Profile object. يُستدعى لإعادة القراءة بعد تعديل (لأن التعديل قد **يمسح** حقلاً).

### 5.5 تعديل بيانات موظف

**الصلاحية:** `employees.edit`.

```
PATCH /employees/{profileId}
```

**Request (كل الحقول تُرسل دائماً؛ null تعني مسح القيمة):**

```json
{
  "first_name": "أحمد",
  "father_name": "محمد",
  "surname": "الخطيب",
  "job_title_id": "uuid | null",
  "gender": "male | female | null",
  "mission_type_id": "uuid | null",
  "date_of_birth": "1980-05-14 | null",
  "city_id": "uuid | null",
  "phone_sy": "+963... | null",
  "phone_sa": null
}
```

**Response:** `204`. لا يمس الأعمدة المحمية إطلاقاً.

### 5.6 حذف حساب (بديل Edge Function `admin-delete-user`)

**الصلاحية:** `employees.delete` (الأدمن يحملها ضمنياً).

```
DELETE /admin/employees/{profileId}
```

**Response 200:** `{ "id": "uuid" }`

**قواعد رفض إلزامية (كما في الدالة الحالية):**

- `400 cannot_delete_self` — حذف النفس.
- `400 cannot_delete_admin` — حذف أدمن (يُنزع عنه الأدمن أولاً).
- `404 not_found` — معرف غير موجود.
- الحذف يشمل **مستخدم Auth** فيتسلسل على: profile، عضويات الملفات، مشاركات
  المواسم، الإشعارات، أجهزة الدفع.

### 5.7 تعيين كلمة سر لموظف (بديل Edge Function `admin-set-password`)

**الصلاحية:** `employees.password`، مع رفض تغيير كلمة سر **أدمن** لغير الأدمن.

```
PUT /admin/employees/{profileId}/password
```

**Request:** `{ "password": "newSecret" }` — **Response:** `204`.

### 5.7b تغيير البريد الإلكتروني لموظف (بديل Edge Function `admin-set-email`)

**الصلاحية:** `employees.email`، مع رفض تغيير بريد **أدمن** لغير الأدمن.
(الدالة نفسها تسمح لأي مستخدم مقبول بتغيير بريده **هو** دون صلاحية — §2.7.)

```
PUT /admin/employees/{profileId}/email
```

**Request:** `{ "email": "new@example.com" }` — **Response:** `200 { "id", "email" }`.

**قواعد رفض إلزامية (كما في الدالة الحالية):**

- `400 email_invalid` — صيغة بريد غير صالحة.
- `400 email_taken` — البريد مستخدم من حساب آخر (فرادة `auth.users`).
- `403 cannot_set_admin_email` — بريد أدمن لغير الأدمن.
- `404 not_found` — معرف غير موجود.
- البريد يُكتب **مؤكَّداً** (لا تُرسل رسالة تحقق)، وعمود `profiles.email` مرآة
  تتبعه تلقائياً عبر trigger (migration 0026).

### 5.8 إيقاف / إعادة تفعيل

**الصلاحية:** `employees.suspend`.

```
PATCH /employees/{profileId}/suspension
```

**Request:** `{ "is_suspended": true }` — **Response:** `204`.

### 5.9 التصنيف الخارجي

**الصلاحية:** `employees.external`.

```
PATCH /employees/{profileId}/external-status
```

**Request:**

```json
{
  "is_external": true,
  "organization": "وزارة الخارجية",
  "external_title": "مندوب"
}
```

عند `is_external = false` يمسح الخادم الحقلين الآخرين. **Response:** `204`.

---

## 6. الموافقات Approvals

**الصلاحية:** `approvals.view` للقائمة، `approvals.decide` للقرار.

### 6.1 قائمة الانتظار

```
GET /approvals/pending
```

حسابات `pending` مرتبة بـ `updated_at` تنازلياً. **Response:** `[Profile]`.

### 6.2 اعتماد

```
POST /approvals/{profileId}/approve
```

يضبط `account_status = approved` ويمسح `rejection_reason`. **Response:** `204`.

### 6.3 رفض

```
POST /approvals/{profileId}/reject
```

**Request:** `{ "reason": "الصورة غير واضحة" }` (اختياري — الفارغ يُخزن null).
يضبط `account_status = rejected`. **Response:** `204`.

### 6.4 عرض وثيقة خاصة

**الصلاحية:** `employees.documents`. رابط موقّع لوثيقة في bucket `documents`
صلاحيته 600 ثانية — انظر §19.3.

---

## 7. المواسم Seasons

**الصلاحية:** `seasons.view` هي الباب؛ `seasons.switch` لتغيير الموسم الحالي؛
`seasons.participants_view` / `seasons.participants_manage` للمشاركين.

### 7.1 ضمان موسم السنة الحالية (بديل RPC `ensure_current_season`)

يُستدعى عند فتح شاشة المواسم: ينشئ صف الموسم لسنة هجرية إن لم يوجد، ويجعله
الحالي **إن كان أحدث** ولم يكن ثمة تثبيت يدوي لهذه السنة (§21.6).

```
POST /seasons/ensure-current
```

**Request:** `{ "hijri_year": 1448, "label": "2026/2027" }`
**Response 200:** `{ "id": "uuid" }`

> `label` هو `gregorian_label` ويشتقّه التطبيق من **امتداد السنة الهجرية
> نفسها** (ميلادية أول يومها إلى ميلادية آخر يومها عبر تحويل أم القرى) — لا من
> سنة الجهاز الحالية، التي كانت تخطئ نصف السنة (من يناير حتى رأس السنة
> الهجرية). خادم بديل يحسبه بنفسه يجب أن يحسبه بالطريقة ذاتها.

### 7.2 كل المواسم

```
GET /seasons
```

**Response (مرتبة hijri_year تنازلياً):**

```json
[
  {
    "id": "uuid",
    "hijri_year": 1448,
    "gregorian_label": "2027",
    "is_current": true,
    "pinned_for_hijri_year": null,
    "created_at": "..."
  }
]
```

### 7.3 الموسم الحالي

```
GET /seasons/current
```

**Response 200:** Season object، أو `404` إن لم يوجد.

### 7.4 تعيين الموسم الحالي (بديل RPC `set_current_season`)

```
POST /seasons/{seasonId}/set-current
```

**Request:** `{ "pinned_for_hijri_year": 1448 }` — تسجيل السنة الهجرية التي
اتُّخذ فيها القرار كي لا يدوسه التقدّم السنوي التلقائي (7.1).
**Response:** `204`. عملية ذرّية: موسم واحد فقط `is_current = true`.

### 7.5 مشاركو موسم

```
GET /seasons/{seasonId}/participants
```

المشاركون بحالة `active` مع الـ profile كاملاً. **Response:** `[Profile]`.

```
GET /seasons/{seasonId}/participants/ids
```

**Response:** `{ "profile_ids": ["uuid", ...] }` — نسخة خفيفة تُستخدم للمقارنة.

### 7.6 سِجل مشاركة موظف

```
GET /profiles/{profileId}/participation-history
```

مواسم المشاركة `active` فقط (المسحوب ليس مشاركة). **Response:** `[Season]` الأحدث أولاً.

### 7.7 الموظفون القابلون للإضافة لموسم

```
GET /seasons/assignable-employees
```

كل حسابات `approved` مرتبة بالاسم الأول. **Response:** `[Profile]`.

### 7.8 إضافة/إعادة تفعيل مشارك

```
PUT /seasons/{seasonId}/participants/{profileId}
```

Upsert على `(season_id, profile_id)` بحالة `active`. **Response:** `204`.

### 7.9 سحب مشارك

```
DELETE /seasons/{seasonId}/participants/{profileId}
```

**لا حذف فعلياً** — تُضبط الحالة `withdrawn` حفاظاً على التاريخ. **Response:** `204`.

---

## 8. أنواع الملفات التشغيلية Module Types

النوع هو "مخطط" الملف: حقوله، مستويات شجرته، مهامه ومراحلها، وأدواره بمهام كل دور.

### 8.1 الكتالوج الكامل

```
GET /module-types?active=true
```

**Response 200 (مرتبة sort_order):**

```json
[
  {
    "id": "uuid",
    "code": "tawafa_transport",
    "name_ar": "ملف النقل",
    "name_en": "Transport file",
    "end_condition_ar": "ينتهي بعودة آخر حاج",
    "end_condition_en": "Ends when ...",
    "is_active": true,
    "sort_order": 1,
    "fields": [
      {
        "id": "uuid",
        "key": "decision_date",
        "kind": "date",
        "label_ar": "...",
        "label_en": "...",
        "is_required": true,
        "sort_order": 1,
        "options": {}
      }
    ],
    "levels": [
      {
        "id": "uuid",
        "depth": 1,
        "name_ar": "قطاع",
        "name_en": "Sector",
        "reference_set_id": null,
        "secondary_reference_set_id": null,
        "fields": []
      }
    ],
    "task_groups": [
      {
        "id": "uuid",
        "name_ar": "مرحلة التسكين",
        "name_en": null,
        "sort_order": 1
      }
    ],
    "tasks": [
      {
        "id": "uuid",
        "group_id": "uuid",
        "role_id": null,
        "name_ar": "...",
        "name_en": null,
        "sort_order": 1
      }
    ],
    "roles": [
      {
        "id": "uuid",
        "code": "sector_supervisor",
        "level_id": "uuid",
        "name_ar": "مشرف قطاع",
        "name_en": "Sector supervisor",
        "job_description_ar": "...",
        "sort_order": 1,
        "tasks": [{ "id": "uuid", "name_ar": "...", "sort_order": 1 }]
      }
    ]
  }
]
```

> **مهم:** المهام تأتي مرتين بحسب انتمائها — مهام على مستوى الملف (`tasks`)
> ومهام كل دور (`roles[].tasks`)، ولا تتقاطع المجموعتان.

### 8.2 نوع واحد

```
GET /module-types/{id}
```

**Response:** نفس عنصر 8.1، أو `404`.

---

## 9. الملفات التشغيلية Modules

### 9.1 قاعدة الرؤية (كانت RLS — تصبح منطق خادم إلزامي)

- حامل `modules.view_all` (أو أدمن): يرى **كل** الملفات.
- غيره: يرى فقط الملفات **المفعّلة** (`is_active = true`) التي يحمل فيها دوراً
  (عضوية مباشرة في `module_members` أو عبر عقدة في `module_node_members`).

### 9.2 كيان Module (الاستجابة القياسية)

```json
{
  "id": "uuid",
  "module_type_id": "uuid",
  "module_type": {
    "name_ar": "ملف النقل",
    "name_en": null,
    "end_condition_ar": "...",
    "end_condition_en": null
  },
  "season_id": "uuid",
  "season": { "hijri_year": 1448 },
  "starts_on": "2026-05-01",
  "ends_on": null,
  "decision_number": "123/2026",
  "report_cadence": "daily",
  "data": { "field_key": "value" },
  "is_active": true,
  "created_by": "uuid",
  "created_at": "...",
  "updated_at": "..."
}
```

`report_cadence`: `none | daily | weekly` (قيمة enum `ReportCadence` في التطبيق).
`data`: JSON حر بمفاتيح حقول النوع.

### 9.3 قائمة الملفات

```
GET /modules?season_id={uuid}
```

`season_id` اختياري. **Response:** `[Module]` — الترتيب النهائي يفرضه الخادم:
الموسم الأحدث أولاً ثم الأحدث إنشاءً.

### 9.4 ملف واحد

```
GET /modules/{id}
```

**Response:** Module أو `404`.

### 9.5 ملف من نوع محدد في موسم محدد

النوع لا يتكرر في الموسم — يُستشار قبل عرض خيار الإنشاء.

```
GET /modules/lookup?module_type_id={uuid}&season_id={uuid}
```

**Response 200:** Module، أو `404` إن لا يوجد.

### 9.6 إنشاء (مسودة)

**الصلاحية:** `modules.create`.

```
POST /modules
```

**Request:**

```json
{
  "module_type_id": "uuid",
  "season_id": "uuid",
  "starts_on": "2026-05-01",
  "ends_on": null,
  "decision_number": null,
  "data": {},
  "report_cadence": "none"
}
```

**Response 201:** `{ "id": "uuid" }` — يُنشأ **غير مفعّل**، والخادم يسجّل `created_by`.
**خطأ:** `409 duplicate_module` (نوع مكرر في الموسم).

### 9.7 تعديل

**الصلاحية:** `modules.edit`.

```
PUT /modules/{id}
```

**Request:** نفس حقول 9.6 عدا النوع والموسم:

```json
{
  "starts_on": "2026-05-01",
  "ends_on": null,
  "decision_number": "123",
  "data": {},
  "report_cadence": "daily"
}
```

> `ends_on: null` **تعني المسح فعلاً** — لا تتجاهلها. `report_cadence` إن غابت لا تتغير.

**Response:** `204`.

### 9.8 تفعيل / إلغاء تفعيل

**الصلاحية:** `modules.activate`.

```
PATCH /modules/{id}/active
```

**Request:** `{ "is_active": true }` — **Response:** `204`.
**أثر جانبي إلزامي:** التفعيل يُنشئ إشعاراً لكل شخص معيَّن في الملف
(كان trigger `modules_notify_activation`) — انظر §21.5.

### 9.9 حذف

**الصلاحية:** `modules.delete`.

```
DELETE /modules/{id}
```

**Response:** `204`. يتسلسل على العقد والأعضاء والتقارير والتقييمات ومرفقاتها.

### 9.10 البحث عن موظفين قابلين للإسناد (بديل RPC `assignable_employees`)

**الصلاحية:** `modules.members`. بحث مُرقَّم على الخادم مع **مطابقة عربية مطوَّعة**
(همزات/تاء مربوطة موحّدة — دالة `ar_fold` تطبَّق على الطرفين).

```
GET /modules/assignable-employees?season_id={uuid}&query={text}&is_external={bool}&job_title_id={uuid}&city_id={uuid}&only_free={bool}&limit=40&offset=0
```

| المعامل       | المعنى                                          |
| ------------- | ----------------------------------------------- |
| `season_id`   | إلزامي — مشاركو هذا الموسم النشطون فقط          |
| `query`       | يطابق الاسم الثلاثي **موصولاً** والمسمى الوظيفي |
| `is_external` | ثلاثي القيم: true / false / غائب (الكل)         |
| `only_free`   | استبعاد من يحمل أي دور في أي ملف بالموسم        |

**Response 200:**

```json
[
  {
    "id": "uuid",
    "first_name": "أحمد",
    "father_name": "محمد",
    "surname": "الخطيب",
    "photo_url": null,
    "is_external": false,
    "external_organization": null,
    "external_title": null,
    "job_title_name": "طبيب",
    "job_title_name_en": "Physician",
    "phone_sy": "+963...",
    "phone_sa": null,
    "account_status": "approved",
    "assignments": [
      {
        "module_id": "uuid",
        "module_name_ar": "ملف النقل",
        "place": "قطاع 1",
        "role_ar": "مشرف"
      }
    ]
  }
]
```

### 9.11 كل مشاركي الموسم النشطين (لحلّ الأسماء داخل المحرر)

```
GET /seasons/{seasonId}/active-participants
```

**Response:** `[Profile]` (بلا الموقوفين)، مرتبة بالاسم.

---

## 10. شجرة الملف Nodes

العقدة = قطاع أو برج/مخيم بحسب `level_id`. تحمل إما `reference_item_id`
(حين يستمد المستوى من البيانات المرجعية — البرج فندق) أو `label` (اسم حر).
منذ 0051 قد تحمل أيضاً `secondary_reference_item_id` (ارتباط ثانٍ — برج ↔ مجموعة).

### 10.0 لا يُنشأ شيء داخل ملف (migrations 0095 + 0096)

> **0096 لازم.** نُفِّذ 0095 بنسختين: الأولى صنعت قائمةً لكل **ملف**
> (`makkah_sectors`, `mashaaer_sectors`, `arafat_centers`, `mina_centers`,
> `mina_camps`)، والثانية قائمةً لكل **صنف**. ولم تستطع الثانية تصحيح الأولى لأن
> كل عبارات نقل البيانات فيها مشروطة بـ `n.reference_item_id is null`، وكانت
> العقد قد رُبطت. 0096 يدمج الأولى في الثانية وينقل العقد ويحذف القوائم القديمة
> بحُرّاس. على قاعدة نظيفة لا يفعل شيئاً.

`label` لم يعد يُستعمل في أيّ مستوى قائم. سبعة مستويات كانت تُكتب باليد —
قطاعات مكة والمشاعر، مراكز عرفات ومنى، مخيمات منى، شركات الخدمة، ومخيمات عرفات
التي وجّهها 0050 إلى قائمة ووُجدت في الكتالوج الحيّ بلا قائمة — صارت كلّها
تستمدّ من `reference_sets`. **الملف شجرة اختيارات وإسنادات، لا مكان إنشاء.**

**قائمة واحدة لكل صنف.** مسوّدة أولى صنعت قائمتَي قطاعات وقائمتَي مراكز، استدلالاً
من التهجئة: مكة تكتب «القطاع الأول» والمشاعر «القطاع 1». وهي قسمةٌ واحدة كُتبت
بوجهين، والأرقام تُطبَّع إلى الحروف في الترحيل. مكة تشغّل خمسةً من السبعة،
والمشاعر تشغّلها كلّها.

| القائمة | موسميّة | النوع |
| --- | --- | --- |
| `sectors` القطاعات | **نعم** (0097) | — |
| `centers` المراكز | **نعم** (0097) | `site` → المشعر |
| `camps` المخيمات | **نعم** | `site` → المشعر |
| `service_companies` شركات الخدمة | لا | — |
| `holy_sites` المشاعر | لا | منى · عرفات |

**والقوائم الستّ التي يُبنى منها الموسم كلّها موسميّة** — الفنادق والتكتلات
(0040)، المجموعات (0064)، المخيمات (0095)، القطاعات والمراكز (0097). حجّة 0095
بأن «القطاع الثالث» اسمٌ ثابت فلا يُوسم صحيحةُ المقدّمة فاسدة النتيجة: الاستيراد
(0043) هو ما يمنع إعادة الكتابة، والسؤال لم يكن عن الاسم بل عن **ما هو القطاع** —
كم عددها، أيّ الأبراج تحتها، من يشغّلها — وذلك يُحسم كل موسم. وبلا وسم، تعديل
قطاعات هذا العام يمتدّ إلى الوراء فيُعيد كتابة ما تقوله ملفات الموسم الماضي.

**والنوع جزءٌ من الهويّة لا وصفٌ عليها.** «المخيم رقم 11» موجود في منى وفي عرفات
وبينهما كيلومتر. لذلك:

- `reference_items.variant` — عمود مولَّد من `data->>'site'`، دخل في
  `uq_reference_items_name_per_season`. الاسم فريدٌ ضمن (القائمة، الموسم،
  **النوع**). القوائم بلا أنواع تُبقيه `null` فتحتفظ بقاعدة 0040 كما هي.
- `module_type_levels.reference_filter` **(جديد، jsonb)** — يُضيّق القائمة إلى
  شريحة المستوى: `{"site": "<uuid منى>"}`. بدونه كان ملف منى سيعرض مخيمات عرفات،
  ومخيمٌ في المشعر الخطأ خطأٌ لا تلتقطه قاعدة لاحقة — الصفّ سليم البنية وكاذب فقط.
  المطابقة بالاحتواء: كل مفتاح موجودٌ ومساوٍ. مفتاحٌ مجهول يُضيّق إلى **لا شيء**
  لا إلى الكل، عمداً.

| الحقيقة | مكانها | لماذا |
| --- | --- | --- |
| المشعر، موقع المخيم، طاقته | **المدخل** `reference_items.data` | تخصّ الأرض، وتُنقل للموسم التالي باستيراد 0043 |
| رقم الخيمة، الجهات المخصّصة | **العقدة** `module_nodes.data` | تخصّ حصّة المكتب من الأرض، وتتبدّل كل موسم |

**و`uq_module_nodes_entry` تغيّر شكله.** كان `(module_id, level_id,
reference_item_id)` — المدخل مرّة واحدة في الملف. صار يضمّ
`coalesce(entry_slot, '')`، و`entry_slot` عمودٌ مولَّد من `data->>'tents'`.
السبب أن العقدة ليست المخيم بل **حصّة المكتب فيه**: عرفات تحمل «المخيم رقم 16 —
خيمة 154» و«خيمة 158»، ومنى تحمل المخيم 16 بخيمة 32 وبخيام 35+36 — مخيمٌ واحد،
حصّتان، وجهات وأشخاص مختلفون في كلٍّ منهما. المستويات التي لا حقل خيمة لها
تُبقيه `null` فتحتفظ بالقاعدة القديمة: الفندق يدخل الملف مرّة، والتكتل يقف في برج
واحد. (طيّ الـ null إلى `''` داخل الفهرس هو حيلة 0040 نفسها.)

**وقائمة `syrian_cities` أُعيدت تسميتها** إلى «مكاتب إدارة الحج والعمرة» — العضو
ينتمي إلى مكتب الإدارة في محافظته، والمدينة كانت تسميةً للمكتب لا أكثر. **الرمز
`syrian_cities` باقٍ** لأن Dart يقرأه (`ReferenceSetCodes.syrianCities`) وسياسة
0030 تطابق عليه. وأُضيف لها حقل `location` من نوع `location` — والمكتب مبنى
يُقصد، و`node_location` يطابق حقول الموقع **بالنوع** (0092) فلا يحتاج سطراً.

**وما يحتاجه التطبيق سطرٌ واحد:** `ReferenceSet.itemsToOffer(seasonId, filter:)`
يضمّ التضييقين — أيّ موسم، ثم أيّ مشعر — ويستدعيه `node_editor_sheet` بـ
`level.referenceFilter`. أمّا الاختيار بين حقل نصّ ومنتقي قائمة فبقي كما كان، من
`level.isNamedByHand`.

### 10.1 الشجرة كاملة

```
GET /modules/{moduleId}/nodes
```

**Response 200 (مرتبة sort_order) — استعلام واحد يعيد كل شيء:**

```json
[
  {
    "id": "uuid",
    "module_id": "uuid",
    "level_id": "uuid",
    "parent_id": null,
    "reference_item_id": null,
    "reference_item": null,
    "secondary_reference_item_id": null,
    "label": "قطاع العزيزية",
    "data": {},
    "sort_order": 1,
    "members": [
      {
        "id": "uuid",
        "role_id": "uuid",
        "profile_id": "uuid",
        "assigned_by": "uuid",
        "assigned_task_ids": ["uuid"],
        "profile": { "...Profile object with job_title and city..." }
      }
    ]
  }
]
```

### 10.2 إنشاء عقدة

**الصلاحية:** `modules.edit`.

```
POST /modules/{moduleId}/nodes
```

**Request:**

```json
{
  "level_id": "uuid",
  "parent_id": "uuid | null",
  "reference_item_id": "uuid | null",
  "secondary_reference_item_id": "uuid | null",
  "label": "قطاع 1 | null",
  "data": {},
  "sort_order": 0
}
```

**Response 201:** `{ "id": "uuid" }`

### 10.3 تعديل عقدة

```
PATCH /nodes/{nodeId}
```

**Request:** `{ "reference_item_id": null, "secondary_reference_item_id": null, "label": "...", "data": {} }`
(القيم null تعني المسح — التطبيق يرسل الحقول الأربعة دائماً). **Response:** `204`.

### 10.4 حذف عقدة

```
DELETE /nodes/{nodeId}
```

**Response:** `204`. يتسلسل على عقدها الفرعية وكل الأعضاء تحتها.

---

## 11. أعضاء الملف والمهام

### 11.1 أعضاء الملف نفسه (ملف بلا شجرة)

```
GET /modules/{moduleId}/members
```

**Response:** نفس شكل `members` في 10.1 (مع profile كامل + `assigned_task_ids`)،
مرتبة بالاسم الكامل.

### 11.2 إسنادات موظف (أين يخدم؟)

```
GET /profiles/{profileId}/assignments
```

**Response 200 (الموسم الأحدث أولاً):**

```json
[
  {
    "role": { "name_ar": "مشرف قطاع", "name_en": null },
    "place": {
      "node_label": "قطاع 1",
      "level": { "name_ar": "قطاع", "name_en": null },
      "reference_item": { "name_ar": "فندق كذا", "name_en": null }
    },
    "module": { "...Module object (9.2)..." }
  }
]
```

> عنصر بلا `place` = عضوية على الملف نفسه. **الرؤية:** الملفات غير المرئية
> للطالب تُسقَط من النتيجة كلياً (كان `!inner` + RLS).

### 11.3 استبدال حاملي دور على عقدة

**الصلاحية:** `modules.members`.

```
PUT /nodes/{nodeId}/roles/{roleId}/members
```

**Request:** `{ "profile_ids": ["uuid", "uuid"] }`

**سلوك إلزامي (diff لا استبدال أعمى):**

- من في القائمة وموجود: **لا يُلمس** (كي لا يُعاد إشعاره ولا تُمسح مهامه).
- من ليس في القائمة: يُحذف.
- الجديد: يُدرج مع `assigned_by` من التوكن، **ويُنشأ له إشعار إسناد** إذا كان
  الملف مفعّلاً (§21.5).

**Response:** `204`.

### 11.4 استبدال حاملي دور على الملف

```
PUT /modules/{moduleId}/roles/{roleId}/members
```

نفس عقد 11.3 حرفياً. **Response:** `204`.

### 11.5 مهام عضو (قائمة تُسلَّم فرداً فرداً)

```
PUT /members/{memberId}/tasks
```

**Request:** `{ "task_ids": ["uuid", ...] }` — نفس منطق diff (الباقي لا يُلمس
حفاظاً على من أسند ومتى). **Response:** `204`.

> ⚠️ هذا المسار **لم يعد** الطريق الوحيد ولا الطريق العام إلى المهام. يخصّ
> حصراً الأدوار التي قائمتها **قائمة اختيار** (`tasks_are_assigned = true`،
> مثل فريقَي الطوافة والنقل) حيث ما يخصّ الشخص هو ما سُلّم إليه لا ما يوجبه
> المنصب. نظام المهام العام — مهام الملف، ومهام الدور، والمهام الشخصية،
> وحالاتها — في **§25**.

---

## 12. تقارير الملف التشغيلي

### 12.1 قاعدة الرؤية

حامل `modules.reports` يرى تقارير الجميع؛ العضو العادي يرى تقاريره فقط.

### 12.2 قائمة تقارير ملف

```
GET /modules/{moduleId}/reports
```

**Response 200 (الأحدث أولاً):**

```json
[
  {
    "id": "uuid",
    "module_id": "uuid",
    "author_id": "uuid",
    "author": { "...Profile with job_title..." },
    "period_start": "2026-05-01",
    "body": "نص التقرير",
    "created_at": "...",
    "updated_at": "...",
    "attachments": [
      {
        "id": "uuid", "report_id": "uuid", "kind": "image",
        "path": "moduleId/reports/reportId/0_photo.jpg",
        "name": "الاسم الأصلي بالعربية.jpg",
        "mime_type": "image/jpeg", "size_bytes": 12345, "sort_order": 0
      }
    ]
  }
]
```

### 12.3 رفع تقرير الفترة الحالية (بديل RPC `submit_module_report` + Storage)

**أهم قاعدة:** **الفترة تُحسب على الخادم** لا على الجهاز (ساعة الهاتف لا يُوثق بها):

- `report_cadence = daily` ⇒ فترة اليوم؛ `weekly` ⇒ فترة الأسبوع.
- **الرفع مرتين في نفس الفترة = تعديل التقرير الأول** (upsert على
  `(module_id, author_id, period_start)`)، ولهذا يوجد `removed_attachment_ids`.

يُنفَّذ كخطوتين مثل التطبيق الحالي، أو يُدمج بمسار multipart واحد — **التوصية**:

```
POST /modules/{moduleId}/reports        (multipart/form-data)
```

| الجزء                    | النوع      | الوصف                                                                   |
| ------------------------ | ---------- | ----------------------------------------------------------------------- |
| `notes`                  | text       | نص التقرير (اختياري)                                                    |
| `removed_attachment_ids` | JSON array | مرفقات تُحذف من تقرير الفترة الموجود                                    |
| `files[]`                | binary     | المرفقات الجديدة، مع `kind[]` (`image`/`file`) و `name[]` بالاسم الأصلي |

**سلوك المرفقات الإلزامي:**

- `sort_order` يبدأ بعد أعلى قيمة موجودة (إعادة الرفع لا تدوس القديم).
- مفتاح التخزين ASCII فقط (§19.5) بنمط `{moduleId}/reports/{reportId}/{n}_{key}`.
- الاسم العربي الأصلي يُخزَّن في الصف ويُعرض ويُنزَّل به.

**Response 200:** `{ "report_id": "uuid" }`

### 12.4 حذف مرفق تقرير

مضمَّن في 12.3 عبر `removed_attachment_ids` (حذف الصف + ملف التخزين معاً).

---

## 13. التقييمات Ratings

سرية بالتصميم: لا أحد يقرأ صفوف التقييم الخام لغيره أبداً.

### 13.1 تقييماتي في ملف

```
GET /modules/{moduleId}/ratings/mine
```

**Response:** `{ "ratings": { "<ratee_profile_id>": 4, "<ratee_profile_id>": 5 } }`

### 13.2 تقييم زميل (upsert)

```
PUT /modules/{moduleId}/ratings/{rateeId}
```

**Request:** `{ "stars": 4 }` (1–5). قيد فريد `(module_id, rater_id, ratee_id)`.
**قواعد:** المقيِّم والمقيَّم كلاهما عضو في الملف؛ **نافذة التقييم** يفرضها
الخادم (`module_rating_open`: الملف مفعّل وضمن مدته). **Response:** `204`.

### 13.3 سحب التقييم

```
DELETE /modules/{moduleId}/ratings/{rateeId}
```

**Response:** `204` — السحب غير إعطاء نجمة واحدة.

### 13.4 نتيجتي (بديل RPC `my_module_rating`)

ما قاله الآخرون **عني** — متوسط وعدد فقط، بلا أسماء:

```
GET /modules/{moduleId}/ratings/my-summary
```

**Response:** `{ "average": 4.2, "ratings": 7 }` — وعند لا شيء: `{ "average": null, "ratings": 0 }`.

---

## 14. البيانات المرجعية Master Data

قوائم (`reference_sets`) وعناصرها (`reference_items`). بعض القوائم **موسمية**
(الفنادق) وبعضها عام (المدن). لكل قائمة "مخطط عنصر" (`reference_set_fields`).

**الصلاحيات:** `reference.view` قراءة، `reference.edit` كتابة،
`reference.delete` حذف، `reference.import` استيراد بين المواسم.

### 14.1 القوائم كاملة

```
GET /reference-sets?active=true
```

**Response 200 (مرتبة code):**

```json
[
  {
    "id": "uuid",
    "code": "hotels_makkah",
    "name_ar": "فنادق مكة",
    "name_en": null,
    "is_season_scoped": true,
    "fields": [
      {
        "id": "uuid",
        "set_id": "uuid",
        "key": "capacity",
        "kind": "number",
        "label_ar": "السعة",
        "label_en": null,
        "target_set_id": null,
        "is_required": false,
        "sort_order": 1
      }
    ],
    "items": [
      {
        "id": "uuid",
        "set_id": "uuid",
        "season_id": "uuid",
        "name_ar": "فندق كذا",
        "name_en": null,
        "data": { "capacity": 400 },
        "is_active": true,
        "sort_order": 1
      }
    ]
  }
]
```

> `active=true` تصفّي **العناصر** غير المفعّلة (القوائم تعود كلها).
> ملاحظة PostgREST التاريخية: حقل من نوع reference يشير إلى قائمة أخرى عبر
> `target_set_id` — لذلك كانت الحقول استعلاماً منفصلاً؛ في REST تُضمَّن مباشرة.

### 14.2 استيراد عناصر قائمة من موسم لآخر (بديل RPC `copy_reference_items`)

```
POST /reference-sets/{setId}/copy-items
```

**Request:** `{ "from_season_id": "uuid", "to_season_id": "uuid" }`
**Response:** `{ "copied": 12 }`
**قواعد:** نسخ مستقلة تماماً؛ الأسماء الموجودة في الهدف تُتخطى (idempotent).

### 14.3 استيراد قطاعات من ملف آخر (بديل RPC `copy_module_sectors`)

```
POST /modules/{toModuleId}/copy-sectors
```

**Request:** `{ "from_module_id": "uuid" }`
**Response:** `{ "copied": 5 }` — عدد **القطاعات** لا الأشخاص.
**قواعد:** نفس الموسم، نفس المستوى فقط، الاسم الموجود يُتخطى، ويُنسخ مع القطاع
حاملو الأدوار التي يعرفها الملفان **بنفس الكود**.

### 14.4 إضافة عنصر

```
POST /reference-items
```

**Request:**

```json
{
  "set_id": "uuid",
  "name_ar": "فندق جديد",
  "name_en": null,
  "data": {},
  "season_id": "uuid | null"
}
```

`season_id` تكون null للقوائم غير الموسمية. **Response 201:** `{ "id": "uuid" }`.

### 14.5 تعديل عنصر

```
PATCH /reference-items/{id}
```

**Request:** `{ "name_ar": "...", "name_en": null, "data": {} }` — **Response:** `204`.

### 14.6 حذف عنصر

```
DELETE /reference-items/{id}
```

**Response:** `204`، أو **`400 reference_item_in_use`** إذا كانت عقدة/ملف/عنصر آخر
يشير إليه (كان trigger `guard_reference_item_delete` — يجب نقله للخادم §21.7).

> **«حذف الكل»** في شاشة القائمة يكرّر هذا النداء عنصراً بعنصر، لا نداءً جماعياً
> واحداً: الحارس يرفض صفاً واحداً فيسقط الحذف كله، والمطلوب أن يذهب ما يمكن
> ذهابه ويُعدّ الباقي. ويُعاد المرور ما دام مروره السابق قد حذف شيئاً — لأن عنصراً
> مرفوضاً قد يتحرّر بعد زوال ما كان يشير إليه. لا حاجة إلى endpoint جماعي.

---

## 15. القرارات Decisions (الجداول باسم `reports`)

> **تنبيه على التسمية.** ما يحمله هذا القسم هو **قرارات** البعثة — التعاميم
> المرقّمة المنشورة على الجميع. الواجهة تسمّيها «القرارات / Decisions»، وهو ما
> تسمّيه الإدارة. أمّا **المُعرِّفات فلم تتغيّر**: الجدول `reports`، والمسارات
> `/reports` و`/reports/manage`، وأكواد الصلاحيات `reports.*`، وستّ migrations
> حتى 0071 مكتوبة عليها. إعادة تسميتها تغييرُ مخطط وترحيلُ صلاحيات وإعادة منح
> لكل حساب — مخاطرة أثناء موسم، لإصلاح كلمة لا يقرأها إلا مطوّر.
>
> **لا تخلطه بـ«تقرير»**: تلك كلمة صحيحة ومستعملة لشيء آخر تماماً —
> `module_reports`، ما يرفعه العضو على ملفه التشغيلي بدوريّته (§12، migration
> 0044). جدولان وشاشتان وصلاحيتان منفصلة، والعربية تفرّق بينهما الآن.

### 15.1 قاعدة الرؤية

التقرير **المنشور** (`is_published = true`) يقرؤه أي حساب فعّال؛
**غير المنشور** لا يراه إلا حامل `reports.view_all`.
`reports.publish` صلاحية مستقلة عن `reports.edit` (النشر بثّ للبعثة كلها).

### 15.2 كتالوج أنواع التقارير

```
GET /report-types
```

**Response (مرتبة sort_order):**

```json
[
  {
    "id": "uuid",
    "code": "meals_daily",
    "name_ar": "تقرير الوجبات",
    "name_en": null,
    "once_per_season": false,
    "sort_order": 1,
    "fields": [
      {
        "id": "uuid",
        "key": "date",
        "kind": "date",
        "label_ar": "التاريخ",
        "is_required": true,
        "sort_order": 1
      }
    ],
    "columns": [
      {
        "id": "uuid",
        "key": "count",
        "label_ar": "العدد",
        "kind": "number",
        "input": "text",
        "is_expanded": false,
        "is_computed": false,
        "sort_order": 1
      }
    ]
  }
]
```

> `is_computed`: عمود يجمع الأعمدة `is_expanded` — **القيمة تُخزَّن مع الصف**
> (يعيد التطبيق حسابها عند التحرير)، فالخادم لا يحسب شيئاً.

> `once_per_season` (migration `0078`): نوعٌ يُنشأ **مرة واحدة خلال الموسم** —
> أنواع الوجبات الثلاثة (`mashaaer_meal_distribution`, `mashaaer_meal_timing`,
> `mashaaer_meal_components`) عليها `true`. القاعدة في §15.5.

### 15.3 قائمة التقارير

```
GET /reports?season_id={uuid}
```

**قاعدة الفلترة (انتبه):** مع `season_id` تُعاد تقارير ذلك الموسم **والتقارير
العامة** (`season_id IS NULL`) معاً. بدونه: كل المقروء.

**سقف القائمة:** التطبيق يطلب أحدث **200** عنصر (`ReportsRepository.listLimit`)
— دعم `?limit=` كافٍ.

**Response (مرتبة updated_at تنازلياً):** — حقل `data` (رأس التقرير jsonb)
**غير مطلوب في القائمة**؛ التطبيق لا يعرضه فيها ويقرؤه من 15.4 عند الفتح.
إعادته لا تضر، لكن حذفه من الإسقاط يوفّر حمولة فقرات كاملة لكل صف.

```json
[
  {
    "id": "uuid",
    "report_type_id": "uuid",
    "report_type": { "name_ar": "...", "name_en": null },
    "season_id": "uuid | null",
    "season": { "hijri_year": 1448 },
    "title": "تقرير وجبات يوم عرفة",
    "number": "45/2026",
    "data": { "field_key": "value" },
    "is_published": true,
    "created_at": "...",
    "updated_at": "..."
  }
]
```

### 15.4 تقرير واحد كامل

```
GET /reports/{id}
```

**Response:** عنصر 15.3 مضافاً إليه:

```json
{
  "rows": [
    {
      "id": "uuid",
      "report_id": "uuid",
      "data": { "col_key": "قيمة" },
      "sort_order": 1
    }
  ],
  "blocks": [
    {
      "id": "uuid",
      "report_id": "uuid",
      "kind": "paragraph",
      "data": { "text": "..." },
      "sort_order": 1
    }
  ],
  "attachments": [
    {
      "id": "uuid",
      "path": "reportId/0_scan.pdf",
      "name": "الأصل.pdf",
      "mime_type": "application/pdf",
      "size_bytes": 1000,
      "sort_order": 0
    }
  ]
}
```

### 15.5 إنشاء تقرير

**الصلاحية:** `reports.create` (+ `reports.publish` إذا `is_published = true`).

```
POST /reports
```

**Request:**

```json
{
  "report_type_id": "uuid",
  "season_id": "uuid | null",
  "title": "العنوان",
  "number": "45/2026 | null",
  "data": {},
  "is_published": false,
  "rows": [{ "data": { "col": "v" }, "sort_order": 1 }],
  "blocks": [
    { "kind": "paragraph", "data": { "text": "..." }, "sort_order": 1 }
  ]
}
```

> `number` الفارغ يُخزن **null** لا سلسلة فارغة (يؤثر على الفرز والبحث).

**Response 201:** `{ "id": "uuid" }` — الخادم يسجل `created_by`.
**يجب أن تكون العملية transaction واحدة** (رأس + صفوف + كتل).

**قاعدة "مرة واحدة خلال الموسم" (إلزامية على الخادم):** إذا كان النوع
`once_per_season = true` ووُجد تقرير آخر بنفس `report_type_id` ونفس
`season_id` (والـ `null` — العام — سلة قائمة بذاتها تخضع للقاعدة نفسها)،
يُرفض الطلب — **409** ورسالة تحمل الرمز `report_once_per_season` (التطبيق
يطابق عليه نصياً ويعرضه مترجماً). حالياً trigger على `reports`
(migration `0078`) يرفض الإدراج والتعديل معاً؛ التطبيق يمنعها في المحرر
قبل الإرسال، والخادم هو الضامن عند السباق أو القائمة القديمة.

> **مطابقة التطبيق الحالي:** منذ migration `0074` يستدعي التطبيق دالة واحدة
> `save_report(p_report_id, …, p_rows, p_blocks)` تنفّذ الرأس والصفوف والكتل
> في transaction واحدة (إنشاءً وتعديلاً معاً — `p_report_id = null` يعني
> إنشاء). هذا العقد هو نفسه 15.5/15.6 حرفياً؛ لم يعد التطبيق يرسل خمسة طلبات.

### 15.6 تعديل تقرير

**الصلاحية:** `reports.edit` (+ `reports.publish` لتغيير حالة النشر — §21.8).

```
PUT /reports/{id}
```

**Request:** نفس 15.5. **السلوك الإلزامي:** الصفوف والكتل **تُستبدل جملة**
(حذف الكل ثم إدراج الوارد) داخل transaction. **Response:** `204`.

### 15.7 حذف تقرير

**الصلاحية:** `reports.delete`.

```
DELETE /reports/{id}
```

**Response:** `204` (يتسلسل على الصفوف والكتل والمرفقات).

---

## 16. الإشعارات Notifications

### 16.1 النموذج

- كل صف إشعار يخص **مستلماً واحداً** (`recipient_id`).
- البثّ = صفوف كثيرة تشترك في `group_id` واحد، **والمرفقات تُعلَّق على المجموعة**
  لا على الصف (500 مستلم = ملف واحد).
- الإشعار الفردي أيضاً له `group_id` (خاص به).
- الصف قد يحمل `data` بمفاتيح توجيه: `{ "type": "module_broadcast", "module_id": "uuid" }`
  أو `{ "type": "module_assignment", "module_id": "uuid" }` — التطبيق يستخدمها للتنقل.

### 16.2 صندوق الوارد

```
GET /notifications?limit=100
```

**سقف الوارد:** التطبيق يطلب أحدث **100** صف
(`NotificationsRepository.inboxLimit`) — الجدول ينمو ما دام الحساب حياً،
والقراءة بلا سقف كانت تجرّ التاريخ كله. بثّ الـ Realtime البديل (§20) يلتزم
بالسقف نفسه.

**Response (الأحدث أولاً):**

```json
[
  {
    "id": "uuid",
    "group_id": "uuid",
    "recipient_id": "uuid",
    "sender_id": "uuid | null",
    "title": "تم إسنادك إلى ملف تشغيلي",
    "body": "نص | null",
    "data": { "type": "module_assignment", "module_id": "uuid" },
    "read_at": null,
    "created_at": "..."
  }
]
```

### 16.3 مرفقات مجموعة/مجموعات

```
GET /notifications/attachments?group_ids=uuid1,uuid2
```

**Response:**

```json
{
  "uuid1": [
    {
      "id": "uuid",
      "group_id": "uuid1",
      "kind": "image",
      "path": "groupId/0_photo.jpg",
      "name": "صورة.jpg",
      "mime_type": "image/jpeg",
      "size_bytes": 500,
      "sort_order": 0
    }
  ]
}
```

### 16.4 تعليم مقروء

```
PATCH /notifications/{id}/read      → 204   (فقط إن كان read_at null)
POST  /notifications/read-all       → 204   (كل غير المقروء للمستخدم)
```

### 16.5 إرسال لشخص واحد

**الصلاحية:** `notifications.send`.

```
POST /notifications                  (multipart/form-data)
```

| الجزء                           | الوصف              |
| ------------------------------- | ------------------ |
| `recipient_id`                  | uuid المستلم       |
| `title`                         | إلزامي             |
| `body`                          | اختياري            |
| `files[]` + `kind[]` + `name[]` | المرفقات (اختياري) |

**سلوك الخادم الإلزامي:**

1. إدراج صف الإشعار (المصدر الموثوق) وتسجيل `sender_id`.
2. تخزين المرفقات تحت `{group_id}/{i}_{key}` (§19.5).
3. **دفع Push** لأجهزة المستلم عبر FCM — **best-effort**: فشل الدفع لا يفشل الطلب
   (يحل محل Edge Function `send-notification` §17.3).

**Response 201:** `{ "id": "uuid", "group_id": "uuid" }`

### 16.6 بثّ إلى ملف تشغيلي (بديل RPC `broadcast_to_module`)

**الصلاحية:** `notifications.broadcast_module`.

```
POST /notifications/broadcast/module          (multipart)
```

**الأجزاء:** `module_id`, `title`, `body?`, `files[]…`

**سلوك إلزامي:**

- إدراج صف لكل حامل دور في الملف (مباشرة أو عبر أي عقدة) **بعبارة واحدة** —
  الكلفة لا تنمو مع عدد الأعضاء.
- كل الصفوف تحمل نفس `group_id` و `data = { "type": "module_broadcast", "module_id": ... }`.
- دفع FCM واحد إلى topic `module_{module_id}` **بنفس** حمولة data.

**Response 200:** `{ "group_id": "uuid" }`

### 16.7 بثّ عام (بديل RPC `broadcast_to_all`)

**الصلاحية:** `notifications.broadcast_all`.

```
POST /notifications/broadcast/all             (multipart)
```

**الأجزاء:** `title`, `body?`, `season_id?` (null = كل حساب فعّال؛ قيمة = مشاركو
الموسم النشطون فقط)، `files[]…`

**سلوك:** كما في 16.6 مع topic `all`. **Response 200:** `{ "group_id": "uuid" }`

---

## 17. أجهزة الدفع Push / Device Tokens

### 17.1 تسجيل جهاز

يُستدعى عند بدء الجلسة وعند تجديد توكن FCM.

```
PUT /me/devices
```

**Request:** `{ "token": "<fcm token>", "platform": "android" | "ios" }`
Upsert على `(user_id, token)` مع تحديث `updated_at`. **Response:** `204`.

### 17.2 إسقاط جهاز (كتم)

يُستدعى قبل تبديل الحساب وعند الخروج.

```
DELETE /me/devices/{token}
```

**Response:** `204` (لا يفشل إن لم يوجد).

### 17.3 مسؤولية الدفع تنتقل للخادم

Edge Function `send-notification` الحالية تصبح **منطقاً داخلياً** في الـ backend
(لا endpoint يستدعيه التطبيق مباشرة إلا ضمن 16.5–16.7):

- **فردي:** جلب توكنات المستلم من `device_tokens` والإرسال واحداً واحداً عبر
  FCM HTTP v1 (`projects/{pid}/messages:send`) بحساب خدمة Firebase.
- **بثّ:** رسالة واحدة إلى topic (`all` أو `module_{id}`).
- الرسالة: `notification: { title, body }` + `data` **بقيم نصية فقط** (FCM يرفض
  المتداخل) + `android.priority = "high"`.
- **صيغة أسماء الـ topics ثابتة تعاقدياً** — التطبيق يشترك بها بنفسه عبر
  FCM SDK: `all` و `module_{module_id}`. أي تغيير يكسر الأجهزة المنصّبة.
- **تحقق إلزامي من الـ topic** (مطبَّق في `send-notification` الحالية): يُقبل
  حرفياً `all` أو `module_<uuid>` **لملف موجود فعلاً** — أي نص آخر يُرفض بـ
  `400`، فلا يستطيع حامل صلاحية الدفع إلى topic اعتباطي.
- **سرية البث:** اشتراك الـ topics بيد الجهاز لا الخادم (وجهاز حُذف صاحبه من
  ملف يبقى مشتركاً حتى يزامن بنفسه) — فالبث **مكبّر صوت لا ظرف مغلق**: كل ما
  هو حساس يوضع في صف الوارد المحمي بـ RLS، لا في عنوان الدفعة أو نصها.

---

## 18. لوحة المعلومات Dashboard

### 18.1 مواسم اللوحة (بديل RPC `dashboard_seasons`)

```
GET /dashboard/seasons
```

**Response:**

```json
[
  {
    "id": "uuid",
    "hijri_year": 1448,
    "gregorian_label": "2027",
    "is_current": true
  }
]
```

### 18.2 الإحصاءات (بديل RPC `dashboard_stats`)

```
GET /dashboard/stats?season_id={uuid}
```

`season_id` غائب = الموسم الحالي.

**المبدأ التعاقدي الأهم:** كل قسم في الاستجابة **إما موجود أو غائب كلياً** بحسب
صلاحيات الطالب — الغياب يعني "لا يحق لك السؤال" وهو **غير** الصفر. الأعداد
تُحسب **خارج قيود الرؤية** (عدّ فعلي) ثم يُقرَّر ما يُسلَّم:

| القسم                 | شرط الظهور                                          |
| --------------------- | --------------------------------------------------- |
| `people`              | `employees.view`                                    |
| `approvals`           | `approvals.view`                                    |
| `modules`, `ratings`, `reports` (تقارير الملفات) | `modules.view_all` أو `modules.members` |
| `central_reports`     | `reports.view_all`                                  |
| `notifications`       | إحدى صلاحيات الإرسال الثلاث                         |
| `reference`           | `reference.view`                                    |
| `permissions`         | `permissions.view`                                  |

**الأقسام الأربعة المضافة (migration 0075):**

```json
{
  "central_reports": {
    "total": 6, "published": 4, "drafts": 2, "general": 1,
    "by_type": [{ "label_ar": "تقرير الوجبات", "label_en": null, "n": 3 }]
  },
  "notifications": {
    "messages": 5, "recipients": 40, "read": 30, "total_messages": 12,
    "series": [{ "day": "2026-07-30", "n": 2 }]
  },
  "reference": {
    "sets": 3, "items": 20, "active": 18,
    "season_items": 15, "general_items": 5,
    "by_set": [{ "label_ar": "فنادق مكة", "label_en": null, "n": 9 }]
  },
  "permissions": {
    "admins": 2, "grantees": 7, "grants": 21,
    "by_section": [{ "key": "modules", "count": 9 }]
  }
}
```

> `central_reports` يُحصى على الموسم المختار **والتقارير العامة** معاً (قاعدة
> 15.3 نفسها). `notifications` غير موسمي — نافذته آخر 30 يوماً بجانب إجمالي
> تاريخي. `by_section` مفاتيحه أكواد الأقسام الثمانية والتطبيق يعرّبها.

**Response 200 (الشكل الكامل):**

```json
{
  "season": {
    "id": "uuid",
    "hijri_year": 1448,
    "gregorian_label": "2027",
    "is_current": true
  },
  "people": {
    "participants": 250,
    "withdrawn": 5,
    "internal": 200,
    "external": 50,
    "by_mission": [
      { "label_ar": "البعثة الإدارية", "label_en": "Administrative mission", "count": 120 }
    ],
    "by_gender": [{ "key": "male", "count": 180 }],
    "by_job_title": [
      { "label_ar": "طبيب", "label_en": "Physician", "count": 30 }
    ]
  },
  "approvals": {
    "pending": 3,
    "approved": 260,
    "rejected": 4,
    "incomplete": 9
  },
  "modules": {
    "total": 14,
    "active": 9,
    "draft": 5,
    "ended": 2,
    "running": 7,
    "nodes": 120,
    "members": 480,
    "unstaffed": 1,
    "by_type": [
      { "label_ar": "ملف النقل", "label_en": null, "total": 1, "active": 1 }
    ]
  },
  "reports": {
    "total": 300,
    "authors": 45,
    "series": [{ "day": "2026-07-01", "n": 12 }]
  },
  "ratings": {
    "count": 800,
    "rated_people": 300,
    "average": 4.1,
    "distribution": [
      { "stars": 1, "count": 10 },
      { "stars": 5, "count": 400 }
    ]
  }
}
```

> حساب غير فعّال أو موسم غير موجود ⇒ `{ "season": null }`.
> `reports.series`: آخر 30 يوماً بحسب **اليوم الذي يغطيه التقرير** لا يوم كتابته.

---

## 19. الملفات والتخزين Storage

### 19.1 الحاويات (Buckets) وقواعد وصولها

| Bucket          | الخصوصية | المحتوى                  | نمط المسار                                                     | من يقرأ                              |
| --------------- | -------- | ------------------------ | -------------------------------------------------------------- | ------------------------------------ |
| `avatars`       | **عام**  | الصور الشخصية            | `{userId}/{name}`                                              | الجميع (URL عام دائم)                |
| `documents`     | خاص      | جواز/تأشيرة/بطاقة نسك    | `{userId}/{name}`                                              | صاحبها + حامل `employees.documents`  |
| `modules`       | خاص      | مرفقات الملفات وتقاريرها | `{moduleId}/{key}` و `{moduleId}/reports/{reportId}/{n}_{key}` | عضو الملف / حسب رؤية التقرير (§12.1) |
| `notifications` | خاص      | مرفقات الإشعارات         | `{groupId}/{i}_{key}`                                          | مستلم في المجموعة فقط                |
| `reports`       | خاص      | مرفقات التقارير المركزية | `{reportId}/{n}_{key}`                                         | حسب رؤية التقرير (§15.1)             |

### 19.2 رفع ملف

```
POST /files/{bucket}                 (multipart/form-data)
```

| الجزء          | الوصف                      |
| -------------- | -------------------------- |
| `path`         | المسار الكامل داخل الحاوية |
| `file`         | المحتوى الثنائي            |
| `content_type` | اختياري                    |

**سلوك:** upsert (الكتابة فوق الموجود مسموحة). **الصلاحية:** حسب قواعد الحاوية
(الكتابة في `modules/…/reports/…` لعضو الملف؛ في `documents/{uid}` لصاحبها؛ إلخ).

**Response 201:** `{ "path": "..." }` — ولحاوية `avatars` أيضاً:
`{ "public_url": "https://cdn.../avatars/uid/photo.jpg" }`

#### 19.2.1 حدود الحجم (التزام على الطرفين)

الشبكة التي تُرفع عليها هذه الملفات هي شبكة المشاعر في أيام التشريق — أسوأ شبكة
في السنة تحمل أهم مرفقات السنة. فالحدّ ليس تحسيناً بل شرط وصول:

| الطرف   | الحدّ         | كيف يُطبَّق                                                                                   |
| ------- | ------------- | --------------------------------------------------------------------------------------------- |
| العميل  | **25 MB**     | يرفض الاختيار قبل بدء الرفع ويُظهر سبباً بالعربية (`attachmentTooLarge`)                        |
| الصور   | 2048px / q80  | يُعاد ترميزها على الجهاز قبل الرفع — لا تصل صورة أصلية من كاميرا الهاتف إلى الشبكة أبداً        |
| الخادم  | **50 MiB**    | حدّ الحاوية (`supabase/config.toml`). يجب أن يبقى **أعلى** من حدّ العميل لا مساوياً له           |

**التزام الخادم:** يردّ `413 Payload Too Large` مع `{"error": {"code": "file_too_large",
"max_bytes": 52428800}}` بدل خطأ عام — العميل يترجم الكود إلى جملة، ولا يستطيع
ترجمة نصٍّ إنجليزي جاء من الخادم.

**ملاحظة:** حدّ الصور مطبَّق على الجهاز فقط (`lib/core/attachments/attachment_picker.dart`)
لأن إعادة الترميز على الخادم تعني أن الملف قد عبر الشبكة أصلاً — وهو ما يُراد منعه.
الخادم لا يحتاج أن يعرف عنه شيئاً.

### 19.3 رابط موقّع (كل الحاويات الخاصة)

```
POST /files/sign
```

**Request:**

```json
{
  "bucket": "modules",
  "path": "moduleId/reports/reportId/0_photo.jpg",
  "expires_in": 600,
  "download": false,
  "download_name": "الاسم العربي.jpg"
}
```

**Response 200:** `{ "url": "https://...signed..." }`

**قواعد:**

- التوقيع **يمر بفحص الرؤية** — من لا يحق له قراءة الملف لا يحق له توقيعه (`403`).
- `download = true` ⇒ الرابط يقدّم الملف كتنزيل باسم `download_name`
  (header `Content-Disposition: attachment; filename*=UTF-8''...`) بدل عرضه.
- المدد المستخدمة في التطبيق: 600 ثانية (وثائق ومرفقات ملفات)، 3600 ثانية
  (إشعارات وتقارير).

### 19.4 حذف ملف

```
DELETE /files/{bucket}?path={storage path}
```

**Response:** `204`. (يستخدمه حذف مرفق تقرير الملف §12.3.)

### 19.5 قاعدة مفاتيح التخزين (يلتزم بها الطرفان)

أسماء الملفات تصل **بالعربية** ومفتاح التخزين يجب أن يكون ASCII:

- يُشتق المفتاح بإبدال كل ما ليس `[A-Za-z0-9._-]` بـ `_`، ودمج التكرارات،
  وقص البادئات/اللواحق، وقصّ الأساس إلى 60 حرفاً، مع الإبقاء على الامتداد.
- إن أفنى التعقيم الاسم كلياً (اسم عربي صرف) يُستخدم fallback فريد داخل المجلد
  (فهرس رقمي أو مفتاح الحقل).
- **الاسم الأصلي يُخزَّن دائماً في صف قاعدة البيانات** (`name`) وهو ما يُعرض ويُنزَّل به.

---

## 20. البث اللحظي Realtime

التطبيق يستخدم Supabase Realtime **لغرض واحد فقط**: تدفق صندوق إشعارات
المستخدم (إعادة قراءة القائمة عند كل تغيير).

**البديل المطلوب — الحد الأدنى:**

```
WS /ws/notifications          (Authorization عبر query أو header)
```

- عند أي **INSERT / UPDATE / DELETE** على إشعارات المستخدم المتصل، يُرسل الخادم
  حدثاً (يكفي `{ "type": "changed" }` — التطبيق يعيد الجلب عبر §16.2).
- **الشبكة لا يوثق بها:** التطبيق يملك مساري fallback (fetch يدوي + سحب للتحديث)،
  فانقطاع الـ socket يجب ألا يفقد شيئاً — الحقيقة دائماً في `GET /notifications`.
- بديل مقبول إن تعذر WebSocket: **polling** بفاصل قصير، أو دفع FCM صامت
  (data-only) يحرّض إعادة الجلب.

---

## 21. منطق الخادم الإلزامي

> **هذا أهم قسم في المستند.** في Supabase تقوم RLS والـ triggers بعمل لا يظهر
> في أي استدعاء من التطبيق. عند الانتقال إلى REST **كل** ما يلي يجب أن يُعاد
> بناؤه في الـ backend وإلا انكسر النظام بصمت.

### 21.1 مصفوفة الرؤية (بديل RLS)

| المورد           | من يقرأ                                                                                         | من يكتب                             |
| ---------------- | ----------------------------------------------------------------------------------------------- | ----------------------------------- |
| profiles (الغير) | حامل `employees.view`؛ وكل حساب فعّال يرى **زملاءه في ملف مشترك** (دالة `shares_a_module_with`) | `employees.edit` للحقول الوصفية فقط |
| profile (نفسه)   | صاحبه دائماً                                                                                    | صاحبه (الحقول غير المحمية)          |
| modules          | §9.1                                                                                            | حسب صلاحيات modules.\*              |
| module_reports   | كاتبها، أو حامل `modules.reports`                                                               | كاتبها ضمن الفترة                   |
| module_ratings   | **صفوف المقيِّم نفسه فقط** — لا استعلام يعيد تقييمات الغير                                      | المقيِّم ضمن النافذة                |
| notifications    | `recipient_id = current_user` حصراً                                                             | الإدراج عبر مسارات الإرسال فقط      |
| reports          | §15.1                                                                                           | reports.\*                          |
| reference data   | حساب فعّال (+ `syrian_cities`، `job_titles`، `mission_types` لأي مُصادَق)                                       | reference.\*                        |
| seasons          | حساب فعّال                                                                                      | seasons.\*                          |
| device_tokens    | صاحبها فقط                                                                                      | صاحبها فقط                          |

### 21.2 الأعمدة المحمية في profiles

`is_admin`, `is_external`, `account_status`, `is_suspended`, `email`,
`rejection_reason` — لا تتغير إلا عبر مساراتها المخصصة (5.8، 5.9، 6.x) وبصلاحياتها.
أي `PUT /me/profile` يذكرها ⇒ تُتجاهَل أو `403`.

### 21.3 البريد الإلكتروني

`profiles.email` **مرآة** لبريد Auth (كان trigger `sync_profile_email`) —
يقرأ فقط، ويتحدث تلقائياً إن تغير بريد الدخول.

### 21.4 المتطلبات المسبقة للصلاحيات (كان triggers 0073)

- **منح** صلاحية دون أساسها المسجَّل في `permission_prerequisites` ⇒ `400 missing_prerequisite`.
- **سحب** صلاحية ⇒ سحب **كل** توابعها تلقائياً (cascade) في نفس العملية.

### 21.5 إشعارات الإسناد والتفعيل (كان triggers 0017/0024/0058)

يُنشأ إشعار (صف + push) تلقائياً عند:

1. **إضافة عضو** إلى ملف **مفعّل** (مباشرة أو على عقدة) — عنوانه إسناد،
   وdata تشير إلى الملف.
2. **تفعيل ملف** — إشعار لكل شخص معيَّن فيه سلفاً.

لا إشعار عند الإضافة لملف ما يزال مسودة (سيصلهم عند التفعيل).

### 21.6 منطق الموسم الحالي (كان RPC 0016)

- موسم واحد فقط `is_current` في كل لحظة.
- `ensure-current` لا يتقدم تلقائياً فوق اختيار يدوي مثبَّت لنفس السنة الهجرية
  (`pinned_for_hijri_year`).

### 21.7 حماية حذف العنصر المرجعي (كان trigger 0019/0024/0030)

حذف `reference_item` مرفوض (`400 reference_item_in_use`) إذا أشارت إليه:
عقدة ملف (بأي من المرجعين)، أو profile (المدينة)، أو عنصر مرجعي آخر
(حقل من نوع reference داخل `data`).

### 21.8 حُرّاس التعديل (كان triggers 0073)

- **modules:** تعديل `is_active` يتطلب `modules.activate` حصراً؛ باقي الحقول
  `modules.edit` — ولا يجوز خلطهما في طلب واحد بصلاحية واحدة.
- **reports:** تغيير `is_published` يتطلب `reports.publish`؛ باقي الحقول `reports.edit`.

### 21.9 قيود الفرادة (تُترجم إلى 409)

| الجدول              | القيد                                                      |
| ------------------- | ---------------------------------------------------------- |
| modules             | `(module_type_id, season_id)`                              |
| module_reports      | `(module_id, author_id, period_start)` — عبر upsert لا رفض |
| module_ratings      | `(module_id, rater_id, ratee_id)` — upsert                 |
| season_participants | `(season_id, profile_id)` — upsert                         |
| device_tokens       | `(user_id, token)` — upsert                                |
| user_permissions    | `(user_id, permission_id)`                                 |

### 21.10 حساب فترة تقرير الملف

`period_start` يُحسب على الخادم من `report_cadence` وتوقيت الخادم
(اليوم لليومي، بداية الأسبوع للأسبوعي) — **لا يُستقبَل من العميل أبداً**.

### 21.11 المطابقة العربية المطوَّعة (بحث 9.10)

توحيد قبل المقارنة على **الطرفين**: `أ إ آ ← ا`، `ى ← ي`، `ة ← ه`، حذف التشكيل —
بحيث يجد "احمد" "أحمد". (كانت دالة SQL `ar_fold`.)

---

## 22. قاموس الأخطاء

| `error.code`            | HTTP | السياق                                              |
| ----------------------- | ---- | --------------------------------------------------- |
| `invalid_credentials`   | 400  | دخول خاطئ                                           |
| `email_exists`          | 409  | تسجيل ببريد مستخدم                                  |
| `weak_password`         | 422  | كلمة سر قصيرة/ضعيفة                                 |
| `invalid_refresh_token` | 401  | توكن تجديد ملغى/منتهٍ — التطبيق يحذف الحساب المحفوظ |
| `unauthorized`          | 401  | لا توكن                                             |
| `forbidden`             | 403  | صلاحية ناقصة أو حساب موقوف/غير معتمد                |
| `not_found`             | 404  | غير موجود أو غير مرئي                               |
| `cannot_delete_self`    | 400  | حذف النفس (5.6)                                     |
| `cannot_delete_admin`   | 400  | حذف أدمن (5.6)                                      |
| `missing_prerequisite`  | 400  | منح صلاحية دون أساسها (4.5)                         |
| `reference_item_in_use` | 400  | حذف عنصر مرجعي مستخدم (14.6)                        |
| `duplicate_module`      | 409  | نوع مكرر في موسم (9.6)                              |
| `rating_closed`         | 400  | تقييم خارج النافذة (13.2)                           |
| `invalid_topic`         | 400  | اسم topic غير صالح (17.3)                           |
| `report_once_per_season` | 409 | تقرير ثانٍ لنوع يُقدَّم مرة واحدة في الموسم (15)     |
| `complaint_target_missing` | 400 | شكوى على نوع بلا تحديد ما هي عليه (24.1)          |
| `complaint_target_wrong_set` | 400 | عنصر مرجعي من مجموعة غير التي أُعلنت (24.1)     |
| `complaint_is_immutable` | 400 | محاولة تغيير هدف شكوى أو مقدِّمها بعد إنشائها (24.1) |
| `complaint_locked`      | 400  | ردّ على نقاش أُغلق (24.7)                           |
| `complaint_body_required` | 400 | ردّ فارغ (24.7)                                    |
| `complaint_not_found`   | 404  | شكوى غير موجودة أو القارئ ليس طرفاً فيها (24.5)     |

---

## 23. سجل الأحداث Audit Log

> أُضيف في migration 0077. **مصدر الكتابة الوحيد هو الخادم**: في Supabase الحالي
> يكتب trigger عام (`audit_row_change`) على كل جداول القاعدة التشغيلية سطراً لكل
> INSERT/UPDATE/DELETE مع صورة الصف قبل وبعد وقائمة الحقول المتغيّرة. أي backend
> بديل **ملزم** بنفس المبدأ: التسجيل في طبقة البيانات لا في التطبيق، ولا يوجد أي
> مسار كتابة من العميل.

### 23.1 الكيان `AuditEvent`

```json
{
  "id": 12345,
  "occurred_at": "2026-08-01T09:15:00Z",
  "actor_id": "uuid | null",
  "actor_name": "أحمد محمد الخطيب",
  "actor_photo_url": "https://... | null",
  "action": "insert | update | delete | login | logout",
  "table_name": "profiles",
  "record_id": "uuid | null",
  "record_label": "أحمد محمد الخطيب",
  "old_data": { "...": "الصف كاملاً قبل — للتعديل والحذف" },
  "new_data": { "...": "الصف كاملاً بعد — للإضافة والتعديل" },
  "changed_fields": ["phone_sa", "job_title_id"]
}
```

- `actor_name` لقطة تُحفَظ وقت الحدث وتبقى بعد حذف الحساب؛ عند العرض يُفضَّل
  الاسم الحالي إن كان الحساب ما يزال موجوداً.
- `record_label` تسمية بشرية للسجل تُحسب وقت الكتابة (اسم الموظف، نوع الملف،
  عنوان التقرير…) لتبقى بعد حذف السجل نفسه.
- `table_name` تحمل قيمتين زائفتين إضافيتين: `auth` (الدخول/الخروج وأفعال
  الحسابات) و `storage` (رفع/حذف الملفات).
- تعديل تقرير عبر `save_report` يظهر سطراً واحداً على `reports` مع
  `changed_fields: ["content"]` عندما لا يتغير غير الصفوف/البلوكات
  (لا تُسجَّل `report_rows`/`report_blocks` صفاً صفاً). البث الإشعاري يظهر
  سطراً واحداً مع `new_data.recipients` = عدد المستلمين. `device_tokens`
  لا تُسجَّل إطلاقاً.

### 23.2 `GET /audit-events` — قراءة السجل

**كان:** RPC `audit_events`. **الصلاحية:** `audit.view` (أو أدمن).

| Query param | النوع        | المعنى                                            |
| ----------- | ------------ | ------------------------------------------------- |
| `limit`     | int (≤200)   | حجم الصفحة، افتراضي 50                            |
| `before_id` | bigint       | keyset pagination: أعد ما هو أقدم من هذا المعرّف |
| `actor_id`  | uuid         | حسب الفاعل                                        |
| `actions`   | csv          | `insert,update,...`                               |
| `tables`    | csv          | أسماء جداول (يُرسل التطبيق مجموعة القسم المختار)  |
| `from`,`to` | ISO-8601     | حدود زمنية (`to` حصرية)                           |
| `q`         | string       | بحث مطوَّع عربياً في `record_label` و `actor_name` |

⇒ `200` مصفوفة `AuditEvent` مرتبة `id desc`.

### 23.3 `GET /audit-actors` — قائمة الفاعلين

**كان:** RPC `audit_actors`. **الصلاحية:** `audit.view`.
⇒ `[{ "actor_id": "uuid", "actor_name": "...", "photo_url": "... | null" }]`
مميّزة ومرتبة بالاسم — خيارات فلتر "الشخص".

### 23.4 `POST /audit-events/auth` — دخول/خروج

**كان:** RPC `log_auth_event(p_event)`. يستدعيه التطبيق بعد كل دخول ناجح
(بكلمة السر، Google، تبديل حساب) وقبل الخروج. الجسم: `{ "event": "login" | "logout" }`.
Best-effort في التطبيق: فشله لا يفشل الدخول. حساب جديد لم يُكمل ملفه بعد
يُسجَّل بالبريد الإلكتروني بدل الاسم.

### 23.5 التزامات الخادم (بديل Triggers 0077)

1. **سطر لكل كتابة** على كل الجداول التشغيلية أياً كان مسارها، مع استثناءات
   §23.1 (الإشعارات سطر واحد للبث، صفوف التقارير عبر رأس التقرير،
   `device_tokens` مستثناة، تعديلات `updated_at` وحدها لا تُسجَّل).
2. **أفعال الحسابات الإدارية** (إنشاء/حذف حساب، إعادة تعيين كلمة سر، تغيير
   بريد — §5.1/5.6/5.7/5.7b) تكتب سطرها بنفسها ناسبةً الفعل لمستدعيه، لأنها
   تجري بصلاحيات النظام؛ `new_data.op` تحمل:
   `create_user | delete_user | set_password | set_email`
   (كلمة السر لا تُسجَّل أبداً — الفعل فقط).
3. **رفع/حذف الملفات** في التخزين يُسجَّل بسطر `table_name: "storage"` يحمل
   `bucket` و `path`.
4. السجل **قراءة فقط** للعميل، ولا يُعدَّل ولا يُحذف منه شيء عبر أي API.

---

## 24. الشكاوى Complaints

> أُضيف في migrations 0079 و 0080. **هذا القسم أخطر ما في المستند**: فيه قاعدة
> تُوقف حساباً بلا تدخّل بشري، وفيه سرّية لا يجوز للتطبيق أن يكون هو من يحرسها.
> كل ما تحت §24.9 «التزامات الخادم» ملزم حرفياً لأي backend بديل.

### 24.1 الكيان `Complaint`

```json
{
  "id": "uuid",
  "created_at": "2026-08-02T09:15:00Z",
  "target_type": "employee | module | report | hotel | cluster | group | other",
  "target_id": "uuid | null",
  "target_label": "أحمد محمد الخطيب",
  "complainant_id": "uuid | null",
  "complainant_name": "string | null",
  "complainant_photo_url": "string | null",
  "body": "نص الشكوى",
  "is_locked": false,
  "is_dismissed": false,
  "reply_count": 3,
  "attachment_count": 2,
  "my_role": "complainant | accused | manager"
}
```

- `target_label` **لقطة** تُكتب وقت التقديم (كما `audit_log.actor_name`)، فتبقى
  الشكوى مقروءة بعد حذف الفندق أو الموظف الذي قُدِّمت عليه.
- الهدف يُخزَّن في القاعدة كأربعة مفاتيح أجنبية اختيارية تحت enum واحد
  (`target_profile_id` / `target_module_id` / `target_report_id` /
  `target_item_id`) مع قيد يفرض «واحد فقط ويطابق النوع». `target_id` في الـ JSON
  هو `coalesce` عليها.
- `hotel` و `cluster` و `group` كلها صفوف في `reference_items`، ويميّزها
  `reference_sets.code`. الخادم **ملزم** بالتحقق أن المجموعة تطابق النوع
  المُعلَن (`complaint_target_wrong_set`).
- **`complainant_*` تكون `null` حين لا يجوز للقارئ أن يعرف.** انظر §24.9.

### 24.2 الكيان `ComplaintMessage` (فقاعة في النقاش)

```json
{
  "reply_id": "uuid | null",
  "created_at": "2026-08-02T10:00:00Z",
  "body": "نص",
  "author_id": "uuid | null",
  "author_name": "string | null",
  "author_photo_url": "string | null",
  "author_role": "complainant | accused | manager",
  "is_mine": false,
  "attachments": [ { "...": "Attachment" } ]
}
```

`reply_id = null` هي الشكوى نفسها — رأس النقاش. `author_role` يعود **دائماً**
حتى حين تُحجب الهوية، ليُسمّى الطرف بلا تسمية الشخص.

### 24.3 `GET /complaints` — السجل

**كان:** RPC `complaints_list`.
**الصلاحية:** لا شيء لـ `scope=mine`؛ `complaints.view` لـ `scope=all`.

| Query param | النوع | المعنى |
| --- | --- | --- |
| `scope` | `mine \| all` | ما قدّمتُه أنا، أو كل شيء |
| `target_type` | enum? | تضييق بالنوع |
| `target_id` | uuid? | شكاوى شيء بعينه (أُضيف في 0080) |
| `include_dismissed` | bool | الافتراضي true |
| `query` | string? | بحث عربي مطبَّع على `target_label` و `body` |
| `limit` / `before` | int / timestamptz | ترقيم keyset، سقف 200 |

⇒ `200` مصفوفة `Complaint` مرتبة `created_at desc`.
**لا يُرجع أبداً** صفاً يكون فيه القارئ هو المشتكى عليه — ذلك عمل §24.4 وحده.

### 24.4 `GET /me/complaints-against` — ما قُدِّم ضدي

**كان:** RPC `complaints_against_me`. **الصلاحية:** حساب مسجَّل فقط.

بلا أي معامل يحدد الشخص، عمداً: لا أحد آخر يمكن سؤالها عنه. ⇒ `200` مصفوفة
`{ id, created_at, body, is_locked, is_dismissed, reply_count, attachments }`
— **بلا أي عمود هوية إطلاقاً**.

> **ملزم:** لا تُشترط حالة «معتمد» هنا. الإيقاف الذي تفرضه هذه الميزة يُسقط
> `is_approved()`، ومن لا يقرأ ما أوقفه لا يستطيع الدفاع عن نفسه.

### 24.5 `GET /complaints/{id}/thread` — النقاش

**كان:** RPC `complaint_thread`. ⇒ `200` مصفوفة `ComplaintMessage` مرتبة زمنياً،
رأس النقاش أولاً. `404 complaint_not_found`، `403` لمن ليس طرفاً.

### 24.6 `GET /profiles/{id}/complaint-standing` — الأرقام

**كان:** RPC `complaints_against`. **الصلاحية:** صاحب الملف أو `complaints.view`.

⇒ `{ distinct_complainants, open_complaints, dismissed_complaints,
is_auto_suspended, forgiven_count }` — **أرقام فقط، ولا اسم واحد**.

### 24.6b `GET /complaints/targets` — ما يمكن الاشتكاء عليه

**كان:** RPC `complaint_targets` (0082). **الصلاحية:** من يملك تقديم شكوى — أي
حساب معتمد، ولا شيء غير ذلك.

| Query param | النوع | المعنى |
| --- | --- | --- |
| `target_type` | enum | `employee \| module \| report \| hotel \| cluster \| group` |
| `query` | string? | بحث بالاسم |
| `limit` | int | الافتراضي 100، سقف 200 |

⇒ `200` مصفوفة `{ id, name, photo_url }` — **ثلاثة أعمدة فقط**.

> **ملزم:** هذا المسار **لا يفحص** `employees.view` ولا `modules.view_all` ولا
> أي صلاحية عرض. تقديم الشكوى بلا صلاحية عمداً، فلو حجبت قائمة الأسماء خلف
> صلاحية الدليل لصار الحق قائماً بلا وسيلة لاستعماله: يفتح الموظف النموذج فلا
> يجد من يسمّيه. وبالمقابل **لا يُوسَّع** ما يُرجَع: اسم ومعرّف وصورة، لا هاتف
> ولا وثيقة ولا حالة حساب — الدليل يبقى خلف صلاحيته.
>
> ما يظهر في كل قائمة: الموظفون المعتمدون عدا نفسه؛ الملفات **المفعّلة** فقط
> (المسودة لم تُسلَّم لأحد)؛ التقارير المنشورة ومسوداتُه هو؛ عناصر المرجع
> الفعّالة. و `other` بلا قائمة أصلاً.
>
> الاسم يأتي من `audit_record_label` نفسها التي تكتب `target_label` على الشكوى،
> فيكون المعروض في القائمة هو المحفوظ على الشكوى — لا اسمان لشيء واحد.

### 24.7 الكتابة

| Endpoint | كان | الصلاحية |
| --- | --- | --- |
| `POST /complaints` ⇒ `{id}` | RPC `file_complaint` | أي حساب معتمد |
| `POST /complaints/{id}/replies` ⇒ `{id}` | RPC `reply_to_complaint` | طرف في النقاش، أو `complaints.reply` |
| `PATCH /complaints/{id}/lock` | RPC `set_complaint_lock` | `complaints.lock` |
| `PATCH /complaints/{id}/dismiss` | RPC `set_complaint_dismissed` | `complaints.dismiss` |
| `DELETE /complaints/{id}` | RLS | `complaints.delete`، أو صاحبها ما لم يُردّ عليها |

**ترتيب إلزامي للمرفقات:** إنشاء الصف ← أخذ الـ id ← رفع الملفات تحته ← تسجيل
صفوف المرفقات. الرفع قبل وجود الصف مرفوض، لأن قاعدة التخزين تبحث عن الشكوى
بالمجلد الأول من المسار.

### 24.8 التخزين

دلو خاص `complaints`. المسار:
`{complaint_id}/{i}_{file}` و `{complaint_id}/replies/{reply_id}/{i}_{file}`
— معرّف الردّ **يتداخل تحت** معرّف الشكوى ليكفي مسندُ قراءة واحد.
**ولا يُوضع معرّف المشتكي في المسار أبداً.**

### 24.9 التزامات الخادم (ملزمة حرفياً)

1. **الإيقاف التلقائي.** إذا بلغ عدد **المشتكين المختلفين** (لا عدد الشكاوى)
   بشكاوى غير مرفوضة على موظف واحد **3**، يُوقَف حسابه في نفس معاملة التقديم.
   النطاق: كل التاريخ. يجب أن يُعاد الحساب أيضاً عند الحذف وعند رفع/إعادة
   الرفض، وتحت قفل يمنع شكويين متزامنتين من قراءة «اثنان» كلتيهما.
2. **إيقاف آلي واحد فقط يُرفع آلياً.** يُوسم الإيقاف الآلي
   (`auto_suspended_at`)؛ ما قرّره إنسان لا تمسّه القاعدة أبداً.
3. **الرفع اليدوي يسامح.** حين يرفع إنسانٌ إيقافاً، يُحفظ عدد المشتكين وقتها
   (`auto_suspend_forgiven_count`) ولا تُعيد القاعدة الإيقاف إلا بتجاوز هذا
   العدد. بدون ذلك تُعيد أولُ شكوى تالية الإيقافَ فوق قرار المدير خلال ثوانٍ.
4. **حراسة الأعمدة.** `is_suspended` و `auto_suspended_at` و
   `auto_suspend_forgiven_count` لا يكتبها إلا حاملُ `employees.suspend`، أو
   القاعدةُ نفسها من داخل معاملتها. في Supabase يتحقق ذلك بعلَم معاملة **مع**
   `pg_trigger_depth() > 1` **مع** حصر الاستثناء بعمودين — الثلاثة معاً، لأن
   أياً منها وحده قابل للتحايل.
5. **السرّية بنيوية لا تجميلية.** المشتكى عليه لا يُمنح قراءة الصف أصلاً؛ يقرأ
   عبر §24.4 و §24.5 فقط. ويشمل الحجب **ردود المشتكي داخل النقاش** و **صورته**
   كما يشمل اسمه.
6. **المدير ليس مديراً لقضيته.** من يحمل `complaints.view` لا يرى الشكوى
   المقدَّمة عليه هو — وإلا صارت الصلاحية باباً لكشف الهوية.
7. **السجل لا يفشي.** تُسقَط `complainant_id` و `author_id` و `body` من
   `audit_log`، ويُترك الفاعل فارغاً عند التقديم والردّ (الرفض والقفل والحذف
   تُنسب لفاعلها). والإيقاف الآلي يُسجَّل بلا فاعل، وإلا سمّى المشتكي الثالث.
8. **الرافع لا يُسمّى في التخزين.** يجب تصفير مالك الكائن في دلو `complaints`،
   وإلا سلّم صفُّ الكائن هويةَ المشتكي لمن يقرأ المرفق.
9. **الإشعار لا يُسمّي.** إشعار «قُدِّمت شكوى بحقك» يُكتب بمرسِل فارغ وبنص خالٍ
   من الأسماء، وكذلك حمولة الـ push.
10. **`complaints.dismiss` تستلزم `employees.suspend`.** الرفض يرفع إيقافاً،
    فمن يرفض يمسك مفتاح الإيقاف؛ ورقة المنح يجب أن تقول ذلك.

---

## 25. المهام Tasks — الملف والدور والشخص

> **migration 0083.** قبله لم تكن المهمة تصل إلى الشاشة إلا **عبر شخص**: تفتح
> الملف، تجد العضو، تقرأ ما يحمله. وكانت `module_assigned_tasks` تسلّم مهاماً
> مسمّاة إلى **عضوية** مسمّاة — فإذا استُبدل الرجل حُذفت مهامه مع صفّه ووصل
> خلفه إلى قائمة فارغة، والعمل لم يتغيّر وإنما تغيّر سجلّه.
>
> بعده تتعلّق المهمة بواحد من ثلاثة، والشخصُ آخرها وأندرها.

### 25.1 النطاقات الثلاثة

| النطاق     | تتبع        | من يراها                            | مفتاح الحالة        |
| ---------- | ----------- | ----------------------------------- | ------------------- |
| `file`     | الملف كله   | كل أعضاء الملف                      | (الملف، المهمة)     |
| `role`     | الدور       | كل من يشغل الدور — أياً كان الشخص  | (الملف، المهمة، **الموقع**) |
| `personal` | شخص واحد    | هو، ومن يدير الملف                  | (الملف، المهمة، الشخص) |

**السطر الأوسط هو الأهم.** «مشرف البرج» منصب يُشغل مرة لكل برج: «جولة يومية على
الغرف» منجزةٌ في برج الصفوة ولم تبدأ في برج النور، وحالةٌ واحدة مشتركة ستكذب على
أحدهما. أما الدور المحمول على الملف نفسه (فريق، كشف) فلا موقع تحته — الملف هو
الموقع، و `node_id = null`.

### 25.2 مصدرا التعريف

المهمة تأتي من أحد اثنين، ولا ثالث:

1. **كتالوج النوع** `module_type_tasks` (موجود منذ 0017/0028): مهام معيارية
   تكتبها الإدارة مرة وتتكرّر كل موسم. `role_id` مملوء ⇒ مهمة دور؛
   `module_type_id` مملوء ⇒ مهمة ملف. لا مهام شخصية في الكتالوج أبداً.
2. **مكتوبة على ملف الموسم** `module_tasks` (جديد): استثناء هذا الموسم وحده،
   بأي نطاق من الثلاثة.

### 25.3 الجداول الجديدة

**`module_tasks`** — مهمة مكتوبة على ملف واحد:

| العمود | النوع | ملاحظات |
| ------ | ----- | ------- |
| `id` | uuid | |
| `module_id` | uuid | → `modules`, cascade |
| `scope` | enum | `file` \| `role` \| `personal` |
| `role_id` | uuid? | مطلوب لـ `role`، ممنوع لغيره |
| `profile_id` | uuid? | مطلوب لـ `personal`، ممنوع لغيره |
| `group_id` | uuid? | مرحلة العمل من `module_type_task_groups` |
| `title_ar` | text | مطلوب |
| `title_en` | text? | **اختياري** خلافاً للكتالوج |
| `description_ar` / `description_en` | text? | |
| `due_on` | date? | |
| `sort_order` | int | |
| `created_by`, `created_at`, `updated_at` | | |

قيد `module_task_scope_shape` يفرض التطابق بين `scope` والعمودين.

**`module_task_status`** — كيف تسير المهمة. **غياب الصف = `not_started`**، فملفٌ
فيه مئتا مهمة لا يكلّف صفاً واحداً قبل أن يبدأ العمل.

| العمود | النوع | ملاحظات |
| ------ | ----- | ------- |
| `id`, `module_id` | uuid | |
| `type_task_id` / `module_task_id` | uuid? | **واحد منهما فقط** (`num_nonnulls = 1`) |
| `node_id` | uuid? | موقع مهمة الدور |
| `profile_id` | uuid? | صاحب المهمة الشخصية |
| `state` | enum | `not_started` \| `in_progress` \| `done` |
| `note` | text? | |
| `updated_by`, `updated_at` | | |

قيدان: `num_nonnulls(type_task_id, module_task_id) = 1` و
`num_nonnulls(node_id, profile_id) <= 1` — الموقع والشخص لا يجتمعان مفتاحاً.
والفرادة على الخمسة مجتمعة (في Postgres عبر `coalesce` لأن `null` لا يصطدم
بـ `null`؛ في backend مخصّص: فرادة منطقية تعامل `null` كقيمة).

**`module_task_attachments`** — نفس أعمدة `module_report_attachments` تماماً
(`status_id`, `kind`, `path`, `name`, `mime_type`, `size_bytes`, `sort_order`).
المسار: `{module_id}/tasks/{status_id}/{file}` داخل دلو `modules`.

### 25.4 `GET /modules/{id}/task-board` — اللوحة

بديل RPC `module_task_board(p_module_id, p_profile_id, p_all)`.

**Query:** `profile_id` (اختياري — لوحة شخص آخر)، `all=true` (اختياري — كل
الملف بدل حصة رجل واحد).

**Response `200`:** مصفوفة مرتّبة **من الخادم**: مهام الملف، ثم مهام الأدوار،
ثم الشخصية؛ وداخل كل نطاق حسب `sort_order` ثم العنوان.

```json
[
  {
    "status_id": "uuid|null",
    "type_task_id": "uuid|null",
    "module_task_id": "uuid|null",
    "scope": "file|role|personal",
    "role_id": "uuid|null",
    "node_id": "uuid|null",
    "profile_id": "uuid|null",
    "group_id": "uuid|null",
    "title_ar": "…", "title_en": "…|null",
    "description_ar": "…|null", "description_en": "…|null",
    "due_on": "2026-08-20|null",
    "sort_order": 3,
    "state": "not_started|in_progress|done",
    "note": "…|null",
    "updated_by": "uuid|null",
    "updated_by_name": "أحمد الخطيب|null",
    "updated_at": "2026-08-03T10:11:00Z|null",
    "can_update": true
  }
]
```

**كيف تُبنى (ملزم):**

1. **الحيازات**: كل زوج (دور، موقع) يشغله الشخص المطلوب — من `module_members`
   بـ `node_id = null`، ومن `module_node_members` بـ `node_id` الخاص به.
   مع `all=true`: كل زوج يشغله **أي** أحد.
2. **التعريفات**: اتحاد خمسة مصادر — مهام الكتالوج للنوع (`file`)، مهام
   الكتالوج لكل دور **مضروبة في مواقع حيازته** (`role`)، ومهام `module_tasks`
   الثلاث بنطاقاتها.
3. **الاستثناء الواحد**: يُستبعد كل دور `tasks_are_assigned = true`. هناك
   القائمة ليست واجبات المنصب بل قائمة اختيار تُسلَّم فرداً فرداً (§11.5)،
   وعرضها كاملة كـ«مهام دوري» يقول لكل عضو في فريق الطوافة إن الثلاث عشرة كلها
   له.
4. **الحالة**: `LEFT JOIN` على `module_task_status` بمطابقة الخمسة
   (`IS NOT DISTINCT FROM`)، و `state` الافتراضية `not_started`.
5. `can_update` تُحسب للقارئ **لا** لصاحب اللوحة: من يقرأ لوحة زميله يرى كل شيء
   ويحرّك ما تسمح به قواعد §25.6 وحدها.

> **ملاحظة مقصودة:** دورٌ لا يشغله أحدٌ بعدُ لا تظهر مهامه ولا حتى مع
> `all=true` — مهمة في منصب شاغر لا يوجبها أحد، وكشف الأدوار غير المُسندة يقرأ
> من الروستر (§11).

### 25.5 `PUT /modules/{id}/task-state` — تحريك مهمة

بديل RPC `set_module_task_state`. **يعيد `status_id`** لأن المرفقات تُخزَّن
تحته، فلا يستطيع العميل رفع شيء قبل وجود الصف.

**Request:**

```json
{
  "type_task_id": "uuid|null",
  "module_task_id": "uuid|null",
  "node_id": "uuid|null",
  "profile_id": "uuid|null",
  "state": "not_started|in_progress|done",
  "note": "نص|null"
}
```

**Response `200`:** `{ "status_id": "uuid" }`

**تحقّقات إلزامية بهذا الترتيب:**

1. صلاحية الكتابة حسب §25.6 — **أولاً**، قبل أي كتابة.
2. `state` من الثلاث المعروفة، وإلا `422` بجملة مفهومة.
3. المهمة تنتمي لهذا الملف: مهمة الكتالوج نوعها = نوع الملف، ومهمة
   `module_tasks` ملفها = هذا الملف. بدون هذا يفتح النداءُ صفَّ حالة لا تقرؤه
   لوحةٌ أبداً ويحمله السجل إلى الأبد.
4. upsert على مفتاح الخمسة (`update` ثم `insert` إن لم يُصب شيء).
5. `note` فارغة أو مسافات ⇒ `null`.

**المرفقات:** `POST /task-states/{statusId}/attachments` و
`DELETE /task-attachments/{id}` — نفس عقد §12.3/§12.4 حرفياً، ونفس دلو
`modules`.

### 25.6 من يكتب ماذا (بديل RLS — ملزم)

**قراءة اللوحة:** مدير، أو حامل `modules.view_all`، أو عضو في الملف. ولوحة
**شخص آخر** لا يقرؤها إلا مدير أو حامل `modules.view_all`.

**تحريك مهمة** — ثلاث قواعد، واحدة لكل نطاق، وواحدة فقط منها صلاحية:

| النطاق | من يحرّكها |
| ------ | ---------- |
| `file` | **أي عضو** في الملف. هذا هو معنى مهمة الملف: القائمة للفريق، ومن يصل إليها أولاً يحرّكها. |
| `role` | من يشغل الدور **في الموقع المذكور**. مشرف برج ينهي برجه ولا ينهي برج غيره. |
| `personal` | الرجل المكتوبة له، لا سواه. |

وفوق الثلاثة: المدير، وحامل `modules.tasks`.

> ⚠️ لا يُسمح بأن تكون هذه القواعد في العميل. النطاق يُقرأ من **صف المهمة** على
> الخادم، لا من حمولة الطلب: عميلٌ يرسل `scope` لنفسه يمنح نفسه الصلاحية.

**كتابة/تعديل/حذف مهمة على الملف** (`module_tasks`): المدير أو `modules.tasks`
حصراً. عضوٌ عادي يحرّك المهام ولا يخترعها.

**الرؤية:**

- `module_tasks`: عضو الملف يرى `file` و `role`؛ ولا يرى `personal` إلا إن كانت
  له. هذا السطر وحده هو ما يجعل «لا تظهر إلا لذلك المستخدم» حقيقةً لا نيّة.
- `module_task_status`: نفس القاعدة (`profile_id is null or profile_id = me`).
- `module_task_attachments`: تتبع صفَّ الحالة الذي تحتها، ولا تعيد شرح شيء.

### 25.7 الصلاحية الجديدة

| الرمز | الوصف | يتطلب |
| ----- | ----- | ----- |
| `modules.tasks` | كتابة مهام الملف وتحديث أي حالة | `modules.view_all` + `employees.view` |

تُمنح تلقائياً في الترحيل لكل من يحمل `modules.members` — وهم بالضبط من يُسندون
المناصب ويوزّعون المهام، ولأن `modules.members` وحدها تضمن المتطلبين معاً.

**ليست** ما يحتاجه العضو ليحرّك عمله: ذلك عضويةٌ لا منحة.

### 25.8 التزامات الخادم (ملزمة حرفياً)

1. **الترتيب من الخادم.** الملف ← الدور ← الشخص. العميل يرسم ما وصله ولا يعيد
   ترتيبه، وإلا اختلف ترتيب الشاشة بين تطبيق وآخر.
2. **الحالة لكل موقع.** مفتاح حالة مهمة الدور يشمل `node_id`. دمجُها يعني أن
   إنهاء برج واحد يُظهرها منجزة عند الجميع — وهو أسوأ من غياب الميزة.
3. **غياب الصف حالة.** لا تُنشأ صفوف حالة استباقياً عند إنشاء الملف.
4. **`can_update` تُحسب للقارئ.** لا لصاحب اللوحة.
5. **المهام المسلَّمة (`tasks_are_assigned`) تبقى خارج اللوحة.** وتُقرأ من
   §11.5 كما كانت.
6. **الإشعار للنطاق الشخصي فقط.** مهمة شخصية تُنشأ في ملف **مفعَّل** ⇒ إشعار
   لصاحبها. مهام الملف والدور تصل مع الإسناد، وإخبار ثلاثمئة رجل بأن مهمة
   تاسعة عشرة أُضيفت هو كيف يتوقّف صندوق الوارد عن أن يُقرأ.
7. **تغيير النطاق ليس تعديلاً.** `PATCH` على `module_tasks` لا يقبل `scope` ولا
   `role_id` ولا `profile_id`: نقل مهمة من رجل إلى الملف كله مهمةٌ أخرى،
   والحالة المسجَّلة عليها كانت مسجَّلة عن شيء آخر.
8. **حذف المهمة يحذف حالتها ومرفقاتها** (`cascade`)، وتُحذف الكائنات من الدلو
   معها.
9. **التخزين.** `{module_id}/tasks/{status_id}/…`: يقرأه عضو الملف، إلا مسار
   حالةٍ شخصية فصاحبها وحده؛ ويكتبه من يملك تحريك تلك الحالة (§25.6).
10. **إصلاح مرافق (0083).** القاعدة الاحتياطية لقراءة دلو `modules` كانت تسأل
    `module_members` وحدها، فمشرفُ برجٍ — لا صفَّ له إلا في `module_node_members`
    — لم يكن يستطيع فتح PDF ملفه. صارت تسأل عضوية الملف بمعناها الكامل (الملف
    أو أي عقدة فيه).

---

## 26. التقييم Evaluations — النموذج والتكليف

> **migration 0084.** للبعثة نوعان مما يُسمّى بالعربية «تقييم»، وهذا المستند
> يفصل بينهما فصلاً تامّاً:
>
> - **§13 تقييم النجوم** (0059): خمس نجوم بين زملاء داخل ملف تشغيلي **منتهٍ**،
>   مجهول للجميع بلا استثناء، بلا أسئلة وبلا مجموع. **باقٍ كما هو، ولم تمسّه
>   هذه الترقية بحرف.**
> - **§26 التقييم بالنموذج** (0084، الجديد): ورقة تكتبها الإدارة، يعبّئها شخص
>   **مسمّى بالاسم** عن جهة **مسمّاة**، وتنتهي بعلامة من مجموع.
>
> خلطهما في جدول واحد كان الخيار الآخر ورُفض: أحدهما رأيُ زميل والآخر وثيقة
> إدارية، وكل قاعدة على أحدهما خاطئة على الآخر.

### 26.1 نصفان يلتقيان عند لحظة التكليف

| النصف       | ما هو                                                              | الصلاحية              |
| ----------- | ------------------------------------------------------------------ | --------------------- |
| **النموذج** | مراحل ← أسئلة ← إجابات، ولكلٍّ علامته                              | `evaluations.templates` |
| **التكليف** | صفٌّ واحد: هذا النموذج، عن هذه الجهة، بيد **مُقيِّم واحد**         | `evaluations.assign`  |
| **التعبئة** | الإجابة والاعتماد                                                  | **لا صلاحية لها**     |

**غياب صلاحية التعبئة هو التصميم لا سهوٌ فيه.** التقييم يصل إلى مُقيِّمه
**بالاسم**، كما يصل الملف إلى أعضائه بالإسناد. صلاحيةٌ هنا تعني «من نثق به
يقيّم من يشاء»، وتقييمٌ لم يطلبه أحد ليس تقييماً.

**وفتحُ التقييم يقع في «إدارة التقييم» وحدها — لا في سجل التقييمات.** السجلّ
سجلٌّ لما جرى، وشاشةٌ تسجّل العمل وتُصدره معاً غرفتان ببابٍ واحد. والفتحُ يجري
**واقفاً على النموذج** الذي ستُعبَّأ عليه الورقة، وهو أيضاً الترتيب الحقيقي
للفعل: النموذج هو ما يحسم أيَّ نوعٍ من الجهات يجوز تسميته بعده، فمن يبدأ من
النموذج لا يختار تركيبةً سيرفضها الخادم.

يترتّب على ذلك أن باب «إدارة التقييم» يقبل **أياً من كودين** —
`evaluations.templates` أو `evaluations.assign` — لا الأول وحده: من يملك الفتح
دون الكتابة يجب أن يصل إلى الشاشة التي يُفتح منها، وإلا صارت صلاحيته بلا باب
تُمارَس منه. وما يفعله كلٌّ منهما داخلها يبقى مفترقاً: أدوات التحرير تسأل
`templates`، وزرّ الفتح يسأل `assign`، والخادم يرفض أياً منهما لغير حامله على
كل حال.

### 26.1b النموذج لفئةٍ لا لجهةٍ بعينها

`target_type` على النموذج هو **فئة** الجهة — «موظف»، «ملف تشغيلي»، «فندق» —
وليس الجهة نفسها. النموذج يُكتب مرة ويُفتح عليه عشرات التقييمات عن جهات مختلفة
وفي مواسم مختلفة؛ ربطُه بملفٍ بعينه يعني إعادة كتابة النموذج بمراحله وأسئلته
وعلاماته لكل ملف، وهو ما لا يفعله أحد مرتين.

فالجهة تُسمّى **عند فتح التقييم** (`assign_evaluation`) لا عند كتابة النموذج،
وهناك وحدها يُستدعى `evaluation_targets` (§26.7). وهذه نقطةٌ أخفقت الواجهة في
قولها فقُرئ صفُّ «يُقيِّم» على أنه منتقٍ فشلت قائمته في التحميل — الصفُّ الآن
يحمل سطراً يقول ما يفعله، ومحرّرُ النموذج يحمل زرَّ «تقييم جديد» ليكمل الطريق
بدل أن ينتهي عند حافة.

### 26.2 المرحلة قسمٌ لا جولة

«المرحلة» في هذا النظام **قسم داخل ورقة واحدة**: «فريق التروية» مرحلة 1 و«الإعاشة»
مرحلة 2 من **التعبئة نفسها**، بيد **الشخص نفسه**، في **جلسة واحدة**. الشاشة
ترسمها خطوات لأن ستين سؤالاً لا تُقرأ في عمود واحد — لا لأن كل خطوة يملكها أحد
غير الآخر. كل سؤال يتبع مرحلة، حتى في نموذج بمرحلة واحدة: جعلُها اختيارية يعني
شكلين للشجرة نفسها ومسارين في كل ما يمشي عليها.

### 26.3 نوعا السؤال

| النوع    | له علامة؟ | له إجابات جاهزة؟ | إجباري؟          |
| -------- | --------- | ---------------- | ---------------- |
| `choice` | **نعم**   | نعم (إجابتان فأكثر)، **لكلٍّ علامتها** | اختياري الضبط |
| `text`   | **لا**    | لا               | اختياري الضبط    |

- **علامة السؤال** هي كامل ما يستحقه، و**لا تتجاوزها علامةُ أي إجابة**.
- **السؤال التحريري بلا علامة إطلاقاً** — لا له ولا لإجابته. `check` في القاعدة:
  `kind <> 'text' or points = 0`. علامةٌ على فقرة يجب أن يمنحها أحد، وذاك الأحد
  هو المُقيِّم يصحّح لنفسه.
- **الإجباري/الاختياري يُسأل عن النوعين معاً**: سؤالٌ تحريري بلا علامة قد يكون
  الشيء الوحيد الذي وُجدت الورقة لجمعه.

### 26.4 المجموع مُشتقٌّ لا مُخزَّن

مجموع النموذج = مجموع علامات أسئلته. مجموع المرحلة = مجموع أسئلتها. **لا عمود
لأيٍّ منهما**: عمودٌ يحمله سيكون نسخة ثانية من حقيقةٍ تتغيّر مع كل تعديل سؤال،
والنسخة هي التي ستُعرض.

### 26.5 الجداول الستة

```
evaluation_templates (id, title, description, target_type, is_active,
                      created_by, created_at, updated_at)
  └── evaluation_stages    (id, template_id, title, description, sort_order)
        └── evaluation_questions (id, stage_id, kind, text, points,
                                  is_required, sort_order)
              └── evaluation_options (id, question_id, text, points, sort_order)

evaluations (id, template_id, season_id, target_type, target_*_id, target_label,
             evaluator_id, assigned_by, note, due_on,
             status, submitted_at, score, max_score, created_at, updated_at)
  └── evaluation_answers (id, evaluation_id, question_id, option_id,
                          stage_title, question_text, question_kind,
                          answer_label, stage_order, question_order,
                          text_answer, points, max_points)
```

`target_type` من `evaluation_target_type` = القيم السبع نفسها التي للشكاوى
(`employee, module, report, hotel, cluster, group, other`)، والجهة **أربعة
مفاتيح أجنبية اختيارية تحت enum** لا `target_id uuid` عارياً — للسبب نفسه في
§24.2.

**`on delete restrict` على `template_id`** وليس `cascade`: نموذجٌ عُبِّئ صار
تاريخاً، وحذفُه يجب أن يفشل بصوت عالٍ لا أن يأخذ العلامات معه. إخراجُ نموذج من
الخدمة هو `is_active = false`.

### 26.6 الإجابة تحمل نصّها — القاعدة المركزية

**كل صفّ في `evaluation_answers` يحمل نسخة من نصّ السؤال وعلامته ومرحلته.**

النماذج تُعدَّل: يُعاد صوغ سؤال في شوّال، والإجابة التي أُعطيت في رجب يجب أن تظلّ
تُقرأ على أنها جوابٌ عمّا سُئل فعلاً. لذلك:

- `question_id` و `option_id` مؤشّران بـ `on delete set null` — يذهبان ولا يأخذان
  السجلّ معهما.
- `question_text`, `answer_label`, `question_kind`, `stage_title`,
  `stage_order`, `question_order`, `points`, `max_points` تُملأ بـ trigger عند
  الكتابة، **ولا يرسلها العميل أبداً**.
- **تقييم معتمَد يُرسم من إجاباته وحدها.** تقييمٌ ما زال مسوّدة يُرسم من النموذج،
  لأنه ما زال يُعبَّأ عليه.

هذا هو `complaints.target_label` (§24.2) مطبَّقاً على ورقة كاملة.

### 26.7 القراءة

| المسار                                                       | يقابل RPC                | من يقرأ                                     |
| ------------------------------------------------------------ | ------------------------ | ------------------------------------------- |
| `GET /evaluation-forms`                                      | `evaluation_forms_list`  | حامل أي من الثلاث صلاحيات                   |
| `GET /evaluation-forms/{id}`                                 | `evaluation_form`        | أي مسجَّل — والمُقيِّم يقرأ نموذجه **ولو أُوقف** |
| `GET /evaluations?scope=mine\|all`                           | `evaluations_list`       | `mine` للجميع، `all` تطلب `evaluations.view` |
| `GET /evaluations/{id}`                                      | `evaluation_sheet`       | المُقيِّم، أو الإدارة، أو **الجهة نفسها منقّحاً** |
| `GET /me/evaluations-about-me`                               | `evaluations_about_me`   | صاحبها وحده — **بلا أي عمود يسمّي المُقيِّم** |
| `GET /evaluations/standing?target_type=&target_id=`          | `evaluations_about`      | الإدارة، وصاحبها عن نفسه                    |
| `GET /evaluation-targets?target_type=&q=`                    | `evaluation_targets`     | حامل `evaluations.assign`                   |

**ولا مسار لاختيار المُقيِّم.** كان هناك واحد (`evaluation_evaluators`) وحُذف:
كان يقرأ `job_titles.name_ar` وهو عمود لم يوجد قط (اسمه `name` منذ 0002، و0046
يشرح لماذا لم يُعَد تسميته حين أُضيف `name_en` بجانبه) — والأهم أنه كان يجيب عن
سؤالٍ للتطبيق جوابٌ أفضل عنه أصلاً. اختيار المُقيِّم يجري على صفحة إسناد
الموظفين نفسها (`assignable_employees` — §9.10، بمرشّحات 0065): بحثٌ في الخادم،
وتصفية بالمسمّى الوظيفي والمدينة، و — وهو بيت القصيد عند تكليف تقييم — **قائمة
بكل ملفٍ يحمله المرشّح هذا الموسم**. من يحمل برجين ومطبخاً ليس الرجل الذي تُعطى
له مهمّة رابعة، وهذه حقيقة يجب أن تُرى وقت الاختيار لا أن تُكتشف بعد أسبوع.

يترتّب عليه أن **بركة المُقيِّمين هي مشاركو الموسم الحالي** لا كل حساب معتمَد،
وهو تضييق مقصود: من ليس في الموسم لا يؤدّي عمل الموسم.

`evaluation_sheet` يعيد الورقة كاملة في نداء واحد: الترويسة + المراحل + الأسئلة
+ ما أُجيب. وفيه `my_role` ∈ `evaluator | subject | manager` و `can_fill`
منطقيّة — **يقرّرهما الخادم**، ولا يشتقّهما العميل من الحالة والدور، لأن
الجوابين اثنان عن سؤال لا يحتمل إلا واحداً.

### 26.8 الكتابة

| المسار                                    | يقابل RPC                      | الصلاحية              |
| ----------------------------------------- | ------------------------------ | --------------------- |
| `PUT /evaluation-forms/{id?}`             | `save_evaluation_form`         | `evaluations.templates` |
| `POST /evaluations`                       | `assign_evaluations`           | `evaluations.assign`  |
| `PUT /evaluations/{id}/answers`           | `save_evaluation`              | **المُقيِّم وحده**     |
| `POST /evaluations/{id}/reopen`           | `reopen_evaluation`            | `evaluations.assign`  |
| `PATCH /evaluations/{id}`                 | `update_evaluation_assignment` | `evaluations.assign`  |
| `DELETE /evaluations/{id}`                | —                              | `evaluations.delete`، أو من فتحه ولم يُمسّ بعد |

**`POST /evaluations` يأخذ مصفوفتين لا معرّفين مفردين**، ويكتب **الجداء
الديكارتي**: تقييمٌ لكل جهة عند كل مُكلَّف. الإدارة لا تسمّي قاضياً واحداً وجهةً
واحدة — تسمّي الثلاثة الذين سيُقيِّمون والأحد عشر ملفاً المطلوب تقييمها، وتعني
الثلاثة والثلاثين.

```json
{
  "template_id": "uuid",
  "target_type": "module",
  "target_ids": ["uuid", "uuid", "…"],
  "evaluator_ids": ["uuid", "uuid", "uuid"],
  "note": "…",
  "due_on": "1447-…"
}
```
⇒ `201 { "ids": ["…", "…"] }` — كلها أو لا شيء، في معاملة واحدة.

**ولا يجوز أن يتقاسم مُقيِّمان ورقة واحدة.** ليس ذلك نسخة أصغر من هذا بل نسخة
مكسورة منه: `evaluation_answers` فريدة على (التقييم، السؤال)، فإجابةُ الثاني
تدوس إجابة الأول بدل أن تقف بجانبها، وعلامةٌ واحدة تُضطر أن تنوب عن حكمين،
وسرّية §26.9 معرَّفة **لكل مُقيِّم** فلا يبقى لها ما تتعلّق به. استقلالُ الأحكام
هو مقصد التقييم، والاستقلالُ صفٌّ لكلٍّ منها.

`assign_evaluation` المفردة باقية غلافاً رفيعاً على الجمعية، حتى يكون لسؤال «ماذا
يجري عند فتح تقييم» جوابٌ واحد.

**`PUT /evaluation-forms` معاملة واحدة** تكتب الشجرة كلها: المُرسَل بـ `id`
يُحدَّث، والغائب يُحذف، و`sort_order` هو موضع العنصر في المصفوفة — وهو ما يجعل
السحب لإعادة الترتيب **حفظاً** لا نداءً لكل صف.

**`PUT /evaluations/{id}/answers` يرسل حالة الورقة كاملة** لا تعديلاً جزئياً:
الإجابات الغائبة من المصفوفة **تُحذف**، لأن مسح سؤال هو ألا تقول عنه شيئاً.

```json
{
  "answers": [
    { "question_id": "uuid", "option_id": "uuid", "text": null },
    { "question_id": "uuid", "option_id": null,   "text": "ملاحظة تحريرية" }
  ],
  "submit": true
}
```

⇒ `200 { "status": "submitted", "score": 38, "max_score": 50 }`

### 26.9 السرّية — من يعرف من قيَّم

القاعدة: **المُقيَّم لا يعرف من قيَّمه أبداً. حاملُ `evaluations.view` يعرف.**
المُقيِّم ليس سرّاً عن الإدارة، وإنما عمّن حكم عليه.

وهي **بنيوية** لا قراراً يتّخذه التطبيق، تماماً كما في §24:

1. **لا صفّ يقرؤه أصلاً.** سياسة `SELECT` على `evaluations` تستثني صراحةً كلَّ
   صفّ يكون القارئ هو جهته: `target_type <> 'employee' or target_profile_id is
   distinct from auth.uid()`. صفٌّ يستطيع اختياره هو صفٌّ يستطيع قراءة
   `evaluator_id` منه.
2. **بابٌ واحد ينقّح.** `evaluations_about_me` **لا يختار عمود المُقيِّم أصلاً**
   — لا يُفرَّغ حقلٌ لم يُقرأ، وهذه فائدة الدالة على العرض (view).
3. **المدير محجوبٌ عن ورقته هو.** وإلا صارت `evaluations.view` هي طريقة معرفة
   من قيَّمك، وأولُ من يلاحظها هو من أُخفيت عنه.
4. **السجلّ ينقّح.** trigger مخصّص على `evaluations` و `evaluation_answers`
   يُسقط `evaluator_id` و `text_answer` من الحمولة، ويكتب **بلا فاعل** حين يكون
   الفاعلُ المُقيِّمَ نفسه. أفعال الإدارة (فتح، إعادة فتح، حذف) تحتفظ بفاعلها —
   وتسمية المدير هي بالضبط ما وُجد السجلّ له.
5. **المسوّدات محجوبة عن الجهة.** `evaluations_about_me` يعيد المعتمَد وحده:
   علامةٌ لم تُعتمد ليست حكماً بعد.

### 26.10 التزامات الخادم (ملزمة حرفياً)

1. **لا endpoint يقبل `score` ولا `max_score` ولا `status`.** العلامة **تُحسب من
   الإجابات** داخل `save_evaluation` ولا تُقبل من أحد — لا من المُقيِّم ولا من
   المدير الذي فتح التقييم. في Postgres تُنفَّذ هذه بأن **لا سياسة `UPDATE`
   على `evaluations` إطلاقاً**؛ في REST تُنفَّذ برفض الحقول الثلاثة في كل مسار.
2. **`score` = مجموع علامات الإجابات. `max_score` = مجموع علامات النموذج.**
   من مصدرين مختلفين عمداً: سؤالٌ اختياري تُرك فارغاً يظلّ محسوباً على المجموع
   الذي كان يستحقّه، وإلا تحسّنت الورقة بتخطّي أسئلتها الصعبة.
3. **الاعتماد يتحقّق من النموذج كما هو الآن.** كل سؤال إجباري في النموذج
   **لحظة الاعتماد** يجب أن يكون مُجاباً؛ النموذج قد يكون كسب سؤالاً بعد فتح
   الورقة، وورقةٌ اعتُمدت على شروط الأمس ورقةٌ فيها ثقب. الخطأ:
   `evaluation_incomplete`.
4. **التجميد إلزامي.** كل إجابة تُخزَّن ومعها نصّ سؤالها وعلامته ومرحلتها
   (§26.6). الخادم يملؤها؛ العميل لا يرسلها ولا يُصدَّق لو أرسلها.
5. **الجهة والنموذج والمُقيِّم ثوابت.** `PATCH` لا يقبل أياً منها: تغييرُ أحدها
   هو فتح تقييم آخر، وله صفّه. الخطأ: `evaluation_is_immutable`.
6. **لا يُفتح تقييم على نموذج موقوف** (`evaluation_form_not_active`)، ولا على
   نموذج نوعُ جهته غير نوع الجهة المطلوبة (`evaluation_form_wrong_target_type`).
   أما إتمام ورقةٍ مفتوحة على نموذج أُوقف لاحقاً فمسموح — الإيقاف يمنع البدء لا
   الإنهاء.
7. **علامة الإجابة ≤ علامة سؤالها**، والسؤال التحريري بلا إجابات جاهزة. القيدان
   **مؤجَّلان إلى نهاية المعاملة** (deferred) لا مُتحقَّق منهما جملةً جملة: خفضُ
   سؤال من 10 إلى 5 مع خفض إجابته من 10 إلى 3 تعديلٌ سليم يفشل إن سبق أحدهما
   الآخر، وترتيبُ الحفظ يجب ألا يكون جزءاً من القواعد. الخطآن:
   `evaluation_option_worth_more_than_question` و
   `evaluation_written_question_takes_no_options`.
8. **`season_id` يُختم من الخادم** من الموسم الحالي عند الإنشاء، ولا يرسله العميل.
9. **`target_label` يُختم مرة واحدة عند الفتح** من الدالة نفسها التي تسمّي
   الصفوف في السجلّ (`audit_record_label`) — لا دالة تسمية ثانية، لأن الاثنتين
   تفترقان.
10. **الإشعارات.** عند الفتح ⇒ إشعار للمُقيِّم باسم من كلّفه. عند الاعتماد وكانت
    الجهة موظفاً ⇒ إشعار له **بلا مُرسِل** (`sender_id = null`): صندوقُ الوارد
    آخرُ مكان يُفشى فيه السرّ، وسيُفشى كاملاً.
11. **الحذف.** حذف التقييم يحذف إجاباته (`cascade`). حذف النموذج **يفشل**
    ما دام عليه تقييم واحد (`restrict`) — وهذا الرفض ميزة لا عائق: العلامات
    المكتوبة عليه تاريخ.
    لكن الرفض يجب ألا يكون طريقاً مسدوداً: `GET /evaluations?template_id=`
    (§26.7) هو ما يُرى منه ما يقف على النموذج، و `DELETE /evaluations/{id}`
    (§26.8) هو ما يُزال به — والواجهة توصل بينهما من بطاقة النموذج نفسها.
12. **تحذير للترقيات اللاحقة.** do-block في 0077 الذي يعلّق trigger السجلّ العام
    على كل جداول المخطّط **يجب ألا يُعاد تشغيله بعد 0084**: سيستبدل بالمنقِّحَين
    (الشكاوى والتقييم) العامَّ، ويبدأ بكتابة `complainant_id` و `evaluator_id`
    في سجلٍّ يقرؤه المدراء.

### 26.11 الصلاحيات الأربع

| الكود                   | ما يفتحه                                       | يشترط              |
| ----------------------- | ---------------------------------------------- | ------------------ |
| `evaluations.view`      | السجلّ كله، بعلاماته وبأسماء مُقيِّميه         | `employees.view`   |
| `evaluations.templates` | كتابة النماذج وتعديلها                         | `evaluations.view` |
| `evaluations.assign`    | فتح تقييم وتسمية مُقيِّمه، وإعادة فتح المعتمَد | `evaluations.view` |
|                         | *(ويفتح له باب «إدارة التقييم» للقراءة — §26.1)* |                    |
| `evaluations.delete`    | حذف تقييم                                      | `evaluations.view` |

**ولا كود خامس للتعبئة** — §26.1.

### 26.12 قاموس أخطاء §26

| الكود                                          | متى                                             |
| ---------------------------------------------- | ----------------------------------------------- |
| `evaluation_not_found`                         | لا تقييم بهذا المعرّف، أو لا حقّ للقارئ فيه     |
| `evaluation_form_not_found`                    | لا نموذج بهذا المعرّف                           |
| `evaluation_form_not_active`                   | محاولة فتح تقييم على نموذج موقوف                |
| `evaluation_form_wrong_target_type`            | النموذج لنوع جهة غير المطلوب                    |
| `evaluation_form_in_use`                       | تغيير نوع جهة نموذج فُتحت عليه تقييمات          |
| `evaluation_target_missing` / `_wrong_set`     | الجهة غير مسمّاة، أو من مجموعة أخرى             |
| `evaluation_evaluator_missing`                 | فتح دفعة بلا مُكلَّف واحد على الأقل             |
| `evaluation_is_immutable`                      | تعديل الجهة أو النموذج أو المُقيِّم             |
| `evaluation_already_submitted`                 | كتابة في ورقة معتمَدة                           |
| `evaluation_incomplete: <نص السؤال>`           | اعتماد وسؤال إجباري بلا إجابة                   |
| `evaluation_question_not_on_this_form`         | إجابة عن سؤال ليس من نموذج هذه الورقة           |
| `evaluation_option_not_on_this_question`       | إجابة مختارة ليست من إجابات سؤالها              |
| `evaluation_option_worth_more_than_question`   | علامة إجابة تتجاوز علامة سؤالها                 |
| `evaluation_written_question_takes_no_options` | إجابات جاهزة على سؤال تحريري                    |

---

## 27. طابور الإرسال Outbox — التزامات الخادم تجاه إعادة الإرسال

**لا endpoint جديدة في هذا القسم.** الطابور يعيش على الجهاز بالكامل
(`lib/core/offline/`) ويستدعي نفس عمليات §12.3 و §25.5. لكنه يغيّر شرطاً واحداً
على الخادم تغييراً جوهرياً، ولذلك يُوثَّق هنا: **كل عملية ميدانية يجب أن تحتمل
إعادة التنفيذ كاملةً.**

### 27.1 لماذا

شبكة المشاعر تغيب ساعات، لا دقائق. قبل الطابور كان الموظف الذي ينقل مهمة إلى
«منجز» أو يرفع تقرير المساء وهي غائبة **يخسر ما كتبه** — وهو واقف في مخيم ولن
يعيد كتابته. الآن تُحفظ العملية على جهازه مع صورها وتُرسل حين تعود الشبكة.

### 27.2 ما يُطابَر وما لا يُطابَر

| العملية                              | تُطابَر؟ | لماذا                                                            |
| ------------------------------------ | -------- | ----------------------------------------------------------------- |
| `set_module_task_state` (+ مرفقاتها) | **نعم**  | تُكتب واقفاً في الموقع (§25.5)                                     |
| `submit_module_report` (+ مرفقاته)   | **نعم**  | تقرير المساء من المخيم (§12.3)                                     |
| كل ما عداها                          | لا       | يُكتب جالساً على اتصال، ويمكن إبلاغ صاحبه بالفشل                    |

**قاعدة الالتقاط:** لا يُحفظ في الطابور إلا الفشل الذي سببه **الشبكة**. رفض
الخادم (صلاحية سُحبت، ملف حُذف، فترة أُغلقت) يُرفع إلى المستخدم فوراً كما كان —
طابور يبتلع الرفض يكذب على صاحبه.

### 27.3 التزامات الخادم

1. **إعادة تنفيذ العملية كاملةً لا تُنتج أثراً مضاعفاً.** الترتيب المعتمد حالياً:
   رفع الملفات أولاً ثم إدراج صفوفها في **statement واحد أخير**، مع ترقيم
   `sort_order` من الموجود فعلاً في الجدول. فمحاولة ماتت قبل الإدراج لم تترك
   صفوفاً، والمحاولة التالية ترقّم من نفس النقطة وتكتب فوق مفاتيح التخزين نفسها
   بـ `upsert`. **على أي backend بديل الالتزام بهذا الترتيب.**
2. **`submit_module_report` تبقى «مرة واحدة لكل فترة»** وتُرجع نفس `report_id` عند
   التكرار (§12.3). هذه الخاصية هي ما يجعل إعادة الإرسال آمنة.
3. **ثغرة معروفة وغير مغطاة:** محاولة نجح إدراجها وضاع ردّها في الطريق ⇒ إعادة
   الإرسال تجد الصفوف وترقّم بعدها، فتصل المرفقات **مرتين**. الكلفة صورة مكرّرة
   لا صورة خاطئة. إغلاقها يحتاج قيد تفرّد على
   `(report_id, path)` و `(status_id, path)` — **غير موجود، ويُنصح بإضافته**
   ومعه `ON CONFLICT DO NOTHING` في الإدراج.
4. **ترتيب الوصول مضمون من العميل:** الطابور يرسل بالأقدم أولاً، فحالتا مهمة
   واحدة (`in_progress` ثم `done`) تصلان بترتيبهما. لا يحتاج الخادم منطقاً لهذا،
   لكنه **يجب ألّا يعيد ترتيبها** أو يعالجها بالتوازي داخل نفس الجلسة.
5. **رمز خطأ الشبكة:** يميّز العميل «الشبكة ساقطة» بنص الاستثناء
   (`SocketException`, `ClientException`, `TimeoutException`, …) — انظر
   `lib/core/utils/network_error.dart`. أي بوابة تحوّل انقطاع الشبكة إلى **502/504
   بجسم JSON** ستكسر هذا التمييز، فيُعامل الانقطاع كرفض ويُفقد العمل. **إن كان
   ولا بد، فليكن الردّ بلا جسم أو بمهلة صريحة.**

### 27.4 سلوك العميل (للعلم فقط)

- **تراجع أُسّي:** 5s → 15s → 45s → 2m → 5m → 15m → 30m (سقف).
- **عودة الشبكة تُلغي التراجع** ولا تنتظره — الإشعار بعودة الراديو معلومة جديدة
  تُبطل تأجيلاً سببه غيابه.
- **ثماني محاولات** ثم يتوقف العنصر وينتظر **إنساناً**: يظهر في `/outbox` بزرّي
  «إعادة المحاولة» و«حذف». الحذف حقّ صاحب العمل وحده.
- المرفقات **تُنسخ** إلى مجلد التطبيق لحظة اختيارها (لا يُعتمد على مسار الكاميرا)
  وتُمسح بعد الإرسال.

---

## 28. تصدير البيانات Export — لا endpoints، ولكن التزام واحد

**لا endpoint جديدة.** شاشة التصدير (`/export` في الإعدادات) تقرأ عبر **نفس**
الاستدعاءات الموثّقة أعلاه، وتكتب الناتج ملفاً على الجهاز. الخادم لا يعلم أن
تصديراً جرى.

### 28.1 ما يُصدَّر وبأي استدعاء

| المجموعة              | الاستدعاء المستخدم                          | الصلاحية التي تُظهرها          |
| --------------------- | ------------------------------------------- | ------------------------------- |
| الموظفون              | `permanent_employees` + `profiles` (§5)     | `employees.view`                |
| مشاركو الموسم         | §7 المشاركون                                | `seasons.participants_view`     |
| الملفات التشغيلية     | §9 قائمة الملفات                            | — (RLS)                         |
| أعضاء ملف             | §11.1 و §10 العقد                           | — (RLS)                         |
| مهام ملف              | RPC `module_task_board` (§25.4) بـ `all`    | — (RLS)                         |
| البيانات المرجعية     | §14 المجموعات وعناصرها                      | `reference.view`                |
| التقارير المركزية     | §15 القائمة                                 | — (RLS)                         |
| الشكاوى               | RPC `complaints_list` بـ `scope=all` (§24.3) | `complaints.view`               |
| التقييمات             | RPC `evaluations_list` بـ `scope=all` (§26.7)| `evaluations.view`              |

### 28.2 الالتزام الوحيد

**التصدير لا يوسّع ما يراه أحد، ويجب أن يبقى كذلك.** الصلاحية في الجدول أعلاه
تقرّر ما إذا كانت المجموعة **تُعرَض** في الشاشة فقط؛ ما يمنع تسرّب صف واحد هو
**سياسة الصفوف على الاستدعاء نفسه**. أي backend بديل يجب أن:

1. يطبّق نفس التضييق على `scope=all` الذي تطبّقه RLS اليوم — الشاشة تطلب «الكل»
   والخادم هو من يقرّر ما هو «الكل» لهذا المستخدم؛
2. يبقي **حجب اسم المشتكي** (§24.9) عاملاً في `complaints_list`. التصدير يكتب ما
   يصله؛ لو أرسل الخادم الاسم لمن لا يستحقه، لصار في ملف يُرسَل بالبريد بدل أن
   يبقى على شاشة.

### 28.3 ملاحظات على الملفات (لا تخصّ الخادم)

- **CSV**: يبدأ بـ BOM (وإلا قرأ إكسل العربية على صفحة ANSI فخرجت طلاسم)،
  ونهايات أسطر CRLF، وسطر `sep=,` لأن الفاصل الافتراضي في ويندوز العربي **فاصلة
  منقوطة**. وكل خلية تبدأ بـ `=`/`+`/`-`/`@` تُسبَق بفاصلة عليا — نصّ حرّ كتبه
  موظف لا يجوز أن يُنفَّذ كصيغة عند فتح الملف.
- **PDF**: بخط التطبيق نفسه (itfQomra) بعد **تحويله من CFF/OpenType إلى TrueType**
  في `assets/fonts/pdf/` — مكتبة `pdf` لا تستطيع تضمين CFF إطلاقاً. تغطية الخط
  للأشكال المتصلة يحرسها `test/pdf_font_test.dart`، لأن نقصها لا يُنتج خطأ بل
  صفحة مربّعات فارغة.
- اسم الملف **ASCII ومؤرَّخ** (`employees-2026-08-04.csv`)؛ العنوان العربي داخل
  الملف حيث يسلم.

---

## 29. التصعيد التلقائي — ملاحظة ما لم يحدث (migration 0086)

كل ما سبق في هذا المستند **ردّ فعل** على فعل: يُنشأ ملف، تُحرَّك مهمة، تُقدَّم
شكوى، فيستجيب trigger أو RPC. لا شيء في النظام كان يراقب **الغياب**. وفي موسم
مدّته أيام، الغياب هو الحدث: مخيّم لم يصل تقريره مساءً هو المخيّم الذي يجب أن
يذهب أحد إليه، ولم يكن يُعرف ذلك إلا بعد انتهاء الموسم عند قراءة الملف.

### 29.1 النطاق — ضيّق عن قصد

**التقرير الدوري فقط**، وبدوريّة `daily` أو `weekly` **فقط**. ملف بدوريّة `once`
يطلب تقريراً بلا تاريخ، فلا يوم يتأخر فيه — واختراع موعد له اختراعٌ لقرارٍ لم
تتّخذه الإدارة. **المهام المتأخرة مسألة أخرى ولم تُمسّ هنا.**

### 29.2 ما أُضيف

| الكائن                                  | الدور                                                       |
| --------------------------------------- | ------------------------------------------------------------ |
| `module_report_period(cadence)`          | تعريف «الفترة الحالية»، **مستخرج** من `submit_module_report`  |
| جدول `report_misses`                     | سجلّ ما هو **مستحقّ ولم يُرفع** (لا سجلّ ما أُرسل)             |
| `module_report_escalation_targets(…)`    | من فوق فلان، درجةً درجة                                       |
| `escalate_missing_reports()`             | المرور اليومي                                                 |
| مهمة pg_cron `escalate-missing-reports`  | `0 17 * * *` — أي ٢٠:٠٠ بتوقيت مكة                            |

### 29.3 السلّم

مأخوذ من بنية الملف لا مخترَعاً: النوع يعلن **مستوياته** (الأول هو الأخرج) وكل
node يسمّي أباه (0024). فمن فوق مشرف البرج هو من يحمل منصباً على قطاع ذلك البرج،
ومن فوقه من يحمل منصباً على الملف نفسه.

| الدرجة | من يُبلَّغ                    | متى            |
| ------ | ----------------------------- | -------------- |
| ٠      | صاحب التقرير نفسه             | مساء اليوم     |
| ١      | حاملو المناصب على العقدة الأب | اليوم التالي   |
| ٢      | حاملو المناصب على الملف       | اليوم الذي يليه|

ثم يتوقف. الإشعار في الدرجتين ١ و٢ **يسمّي الشخص** — مشرف يُقال له «أحدهم متأخر»
أُعطي همّاً لا عملاً، والغرض من رفع الأمر أن يذهب من فوقه فيسأل.

### 29.4 التزامات الخادم

1. **`module_report_period` هي مصدر الحقيقة الوحيد للفترة.** لو اختلف تعريف
   المراقِب عن تعريف المُقدِّم بساعة، لَنبّه رجلاً عن نافذة رفع فيها بالفعل، أو
   سكت عن نافذة لم يرفع فيها. **أي backend بديل يجب أن يشتقّ الاثنين من تعبير
   واحد.**
2. **التوقيت UTC** — كما كان `submit_module_report` دائماً. ليس مثالياً لبعثة
   تعمل على UTC+3، و**لم يُصحَّح عمداً**: تصحيحه في أحد الموضعين دون الآخر يصنع
   بالضبط الاختلاف الذي تمنعه النقطة ١. إن صُحِّح فليُصحَّح **هنا، مرة واحدة**.
3. **الأسبوعي لا يُنبَّه إلا في آخر أيامه** (`current_date >= period_start + 6`).
   نظام يذكّر كل ليلة من الاثنين سيُتجاهَل بحلول الأربعاء.
4. **`escalate_missing_reports()` ممنوعة على `authenticated`.** تكتب في صناديق
   الآخرين؛ لو تُركت متاحة لأمكن لأي حساب تفريغ السلّم كله في إشعارات القيادة.
   يشغّلها المجدول بصلاحية مالك القاعدة.
5. **الإشعار بلا مُرسِل** (`sender_id = null`) — النظام يلاحظ، لا شخص يشتكي.
6. `data.type = 'report_overdue'` مع `module_id`؛ التطبيق يفتح الملف عند اللمس
   (قائمة الأنواع المسموحة في `app_notification.dart`).

### 29.5 التشغيل

`pg_cron` امتداد **يجب تفعيله على المشروع أولاً**. الـ migration يتحقق منه ويطبع
`notice` بدل أن يفشل — كي لا يُعطِّل كل migration بعده:

```sql
create extension pg_cron;
-- ثم أعد تشغيل 0086 كاملاً — كل عباراته قابلة لإعادة التنفيذ
```

**بلا `with schema`:** ملفّ تحكّم pg_cron يثبّت مخططه على `cron` وهو غير قابل
للنقل، فتسمية مخطط آخر **خطأ** لا تفضيل. وعلى Supabase يمكن تفعيله أيضاً من
Database → Extensions — وهو الشيء نفسه بزرّ.

**علامة أن التفعيل لم يحدث:** الـ migration يمرّ بنجاح ولا يجدول شيئاً. الجدول
والدوال موجودة ولا أحد يستدعيها — وهو ما يشبه ميزة عاملة تماماً، إلى أن يمرّ أول
تقرير غائب بلا أن يلاحظه أحد.

**نُفِّذ على قاعدة حيّة** (2026-08-04). يبقى التحقق من أمرين لا يظهران وقت
التنفيذ: أن `pg_cron` مفعَّل فعلاً — وإلا طبع الـ migration `notice` ومضى بلا
جدولة — وأن أول مرور ليلي أنتج ما يُتوقَّع:

```sql
select * from cron.job where jobname = 'escalate-missing-reports';
select escalate_missing_reports();   -- يُعيد عدد الإشعارات المُرسَلة
select count(*), rung from report_misses group by rung;
```

---

## 30. التفقّد الميداني Check-in (migrations 0087 + 0094)

النظام يعرف من **يحمل** منصباً — مشرف البرج السابع صفٌّ في `module_node_members`
منذ 0024. ما لم يستطع قوله قط هو هل هو **واقف** في البرج السابع الآن. وهذا هو
السؤال الذي تطرحه غرفة العمليات فعلاً في الموسم، وكان جوابه الوحيد مكالمة هاتف.

### 30.1 دليلان، ولا يُوثق بأحدهما وحده

| الدليل | يثبت | ثغرته |
| ------ | ---- | ----- |
| **رمز** ملصق على المكان | أنك تنظر إلى هذه البوابة | يُصوَّر ويُمسح من غرفة فندق |
| **موقع الهاتف** مقارَناً بإحداثيات العقدة | أنك قريب من النقطة | يُزوَّر بجهاز مروّت، ويخطئ ٢٠٠م داخل مخيّم معدني |

فيُسجَّل الاثنان، و**المسافة تُحسب في الخادم** لا في الهاتف، والتسجيل الذي لا
يتّسق **يُحفظ ويُوسم، ولا يُرفض أبداً**. الرفض يعني أن رجلاً واقفاً في المخيّم
الصحيح بإشارة GPS رديئة لا يستطيع الإبلاغ بوجوده — وكلفة سجلّ صحيح مفقود، في تلك
الأيام الخمسة، أعلى بكثير من كلفة سجلّ مشكوك فيه يمكن مراجعته لاحقاً.

### 30.2 ما أُضيف

| الكائن | الدور |
| ------ | ----- |
| نوع `check_in_method` | `qr` / `gps` / `manual` |
| جدول `node_check_ins` | الموقع المُبلَّغ، دقّته، المسافة المحسوبة |
| `node_location(node_id)` | إحداثيات العقدة، مستخرجة من حقل `location` في `data` |
| `metres_between(…)` | Haversine — مكتوبة يدوياً بدل تفعيل `cube` + `earthdistance` |
| RPC `check_in_here(…)` | التسجيل. **عضوية لا صلاحية** — كرفع التقرير |
| RPC `module_presence(module_id, since)` | آخر تسجيل لكل شخص في كل مكان |

### 30.3 التزامات الخادم

1. **المسافة تُحسب في الخادم ولا تُقبل من العميل أبداً.** لا سياسة `insert` على
   `node_check_ins` إطلاقاً؛ الكتابة عبر الـ RPC وحدها. مسافةٌ يرسلها الهاتف
   ليست دليلاً على شيء.
2. **`node_location` يجب أن يقرأ الصيغتين** — `?q=lat,lng` (ما يكتبه التطبيق)
   و`@lat,lng` (ما تكتبه روابط Google) — تماماً كما يفعل `MapLocation.parse`
   على الهاتف. لو اختلفا، صارت عقدةٌ يعرض التطبيق دبّوسها عقدةً يظنّ الخادم أنها
   بلا موقع.
3. **`p_node_id` يجب أن يُتحقَّق من انتمائه لـ `p_module_id`.** بدونه يسجّل أحدهم
   وجوده في مكان لم يُسند إليه قط، والاقتران هو كل معنى السجل.
4. **القراءة**: تسجيلك دائماً، وتسجيلات الجميع لحامل `modules.reports` — سجلّ من
   كان أين هو من جنس سجلّ ما رفعوه. و`module_presence` **تُعيد ذكر** هذا الشرط
   لأن دالة `security definer` لا ترث RLS.
5. **الرمز لا يحمل سرّاً ولا يُقصد به ذلك.** `hajjops://check-in?m=…&n=…` —
   مخطّط خاص كي لا يُقرأ باركود منتج أو رمز WiFi كمعرّف عقدة. ما يجعله ذا قيمة
   هو الموقع المسجَّل بجانبه.
6. **تسجيلٌ لا يسمّي مكاناً ولا موقعاً يُرفض** بـ `check_in_needs_a_place`
   (0094). وهذا الالتزام الوحيد الذي يناقض §30.1 ظاهرياً، فيلزم بيان الفرق:
   القاعدة هناك أن التسجيل **المتناقض** يُحفظ ويُوسم — رجلٌ في المخيّم الصحيح
   بإشارة رديئة. أمّا هذا فليس متناقضاً بل **خالياً**: `p_node_id` فارغ
   و`p_lat/p_lng` فارغان، فلا يبقى إلا «أحدهم وصل إلى الملف» — صفٌّ لا يُرسم على
   الخريطة ولا يُعدّ في لوحة الحضور. وهو أسوأ من لا شيء: الرجل يُقال له إنه
   سُجِّل، وغرفة العمليات ترى مخيّماً خالياً.

   والشرط **OR** عمداً: المكان وحده يكفي، والموقع وحده يكفي، وانعدامهما معاً هو
   وحده اللاشيء.

### 30.4 على الجهاز

- **يمرّ بطابور الإرسال** (§27). هذه ثالث كتابة ميدانية وأكثرها يقيناً بأنها
  ستُكتب بلا شبكة: رجل واقف عند بوابة مخيّم في منى يوجّه هاتفه إلى ملصق.
  **والموقع يُلتقط لحظة الضغط لا لحظة الإرسال** — وإلا حمل التسجيل إحداثيات
  المكان الذي أُرسل منه أخيراً، وقد يكون فندقاً في مكة بعد ساعات، ثم يحسب
  الخادم مسافةً على أساس كذبة.
- الوسم `isFarFromPlace` **يطرح دقّة الهاتف من المسافة**: تسجيل على بعد ٤٠٠م من
  هاتف لا يضمن إلا ٥٠٠م ليس دليلاً على شيء، وعلى بعد ٤٠٠م من هاتف يضمن ٨م دليل.
- `CAMERA` أُضيفت إلى AndroidManifest، و`android.hardware.camera` **غير مطلوبة**:
  هاتف بلا كاميرا يحتفظ بكل شيء آخر، والوصول يُسجَّل بالموقع وحده.
- **الورقة تعرض ما يمكن تسميته «هنا»** حين تُفتح بلا عقدة معروفة، وإلا كان
  الالتزام ٦ حائطاً بلا باب. والقائمة **ليست** `is_place` وحده: ذاك يجيب عن
  «أين تُطبع الرموز» (0089) وهو `false` بحقٍّ لشركة الخدمة في المدينة. فحين لا
  مكان في الملف، يقوم مقامَه **أضيق مستوى يملؤه الملف فعلاً** — «مع الشركة
  الرابعة» أقل من مبنى وأكثر بكثير من لا شيء. قراءة `is_place` جواباً كاملاً هي
  ما أخفى القائمة عن تلك الملفات وترك الزرّ ينتهي إلى رفضٍ لا حيلة فيه.
- استعلامٌ فاشل وقائمةٌ فارغة **يبدوان متطابقين على الشاشة**، فالفشل يُسجَّل.

**نُفِّذ على قاعدة حيّة** — 0087 في 2026-08-04، و0094 في 2026-08-05.

---

## 30. البلاغ العاجل Incidents (migration 0088)

الشكوى تطلب **حُكماً لاحقاً**؛ البلاغ يطلب **أن يأتي أحد الآن**. سجلّان مختلفان
عن قصد، وكل خاصية في §24 صحيحة هناك وخاطئة هنا.

| | الشكوى (§24) | البلاغ (§30) |
| --- | --- | --- |
| هوية المُبلِّغ | محجوبة بنيوياً | **معروضة أولاً** — يلزم الاتصال به |
| النموذج | فئة + جهة + هدف | **سطر نصّ واحد** |
| الترتيب | الأحدث أولاً | **الأقدم أولاً** بين المفتوحة |
| الغلق | `complaints.lock` | دورة حياة: `open → in_progress → closed` |

### 30.1 ما أُضيف

| الكائن | الدور |
| --- | --- |
| نوع `incident_state` | `open` / `in_progress` / `closed` |
| جدول `incidents` | البلاغ وموقعه ودورته |
| جدول `incident_attachments` | الأدلة |
| دلو `incidents` (السابع) | `{incident_id}/{i}_{file}` |
| `incidents.receive` / `incidents.handle` | صلاحيتان، والثانية تستلزم الأولى |
| `raise_incident(...)` | يرفع البلاغ **ويُنذر** في معاملة واحدة |
| `set_incident_state(...)` | تحريك الدورة |
| `incidents_list(...)` | السجلّ |
| `has_permission_for(profile, code)` | **جديد وعام** — انظر 30.3 |

### 30.2 التزامات الخادم

1. **الإنذار داخل نفس معاملة الإدراج.** ليس trigger ولا استدعاء من التطبيق: لو
   وُجد الصفّ فقد أُبلغت الغرفة. عميل يكتب الصفّ ثم يموت قبل الإشعار يُنتج
   الفشل الوحيد الذي لا تحتمله هذه الميزة — **طوارئ مسجَّلة لا يعلم بها أحد**.
2. **الرفع بلا صلاحية** (`incidents_insert` تشترط `reporter_id = auth.uid()`
   فقط). نظامٌ لا يُبلِّغ فيه إلا المخوَّلون عن عطل حافلة هو نظام لا يعلم بالعطل.
3. **المُبلِّغ لا يغلق بلاغه** (`incidents_update` لحاملي `incidents.handle`).
   «صار الوضع جيداً» من صاحب البلاغ ليست حقيقة «ذهب أحد وعالجه».
4. **`handled_at` تُختم على أول من يتولّاه ولا تُكتب فوقها** — السؤال هو «كم
   جلس بلا جواب»، وحقلٌ يتحرّك مع كل تعديل لا يجيبه.
5. **المرفقات تُرفع بعد الإنذار** لا قبله (§30.4).

### 30.3 `has_permission_for` — دالة جديدة عامّة

`has_permission` تسأل عن **المستدعي**. الإنذار يسأل عن **الآخرين**، ولم يكن في
المخطط ما يفعل ذلك. تُطابق `has_permission` (0012) حرفياً بما فيه شرطان يسهل
إغفالهما ويَغلى ثمنهما: **الحساب الموقوف وغير المعتمد لا يحمل صلاحية**. بدونهما
يذهب الإنذار إلى من أوقفته الإدارة — ويُحتسب أنه وصل.

### 30.4 ترتيب العمليات في العميل

`raise_incident` أولاً، ثم رفع المرفقات. صورة تستحق الحفظ ولا تستحق الدقيقة التي
تسبق إبلاغ أحد — وعلى شبكة ميدانية قد تكون خمساً.

### 30.5 حالة ثالثة في العميل

`IncidentOutcome` ثلاث لا اثنتان: `sent` / `waitingForNetwork` / `failed`.
«حُفظ وسيُرسل» نجاحٌ في كل مكان آخر في هذا التطبيق و**كذبةٌ هنا**. الحالة
الوسطى تفرض على كل نقطة استدعاء أن تقول صراحة: **لم يُبلَّغ أحد — اتصل هاتفياً**.

**لم يُنفَّذ هذا الـ migration على قاعدة حيّة بعد.**

---

## 31. خريطة الموسم Season map (migrations 0090 → 0093)

كل حقيقة في هذا التطبيق مرتبطة بمكان منذ البداية — البرج فندق له عنوان، والمخيم
له إحداثيات ثبّتتها الإدارة، والوصول يسجّل أين كان الهاتف، والبلاغ العاجل يسجّل
أين كان الرجل واقفاً. ولم يُرسم شيء من ذلك مجتمعاً قط: مكتبة الخرائط في المشروع
منذ 0021 ولم تُستعمل إلا **لاختيار نقطة واحدة** في كل مرة.

### 31.1 `season_map(p_season_id uuid default null)`

`p_season_id` فارغاً يعني الموسم الجاري، ويحلّه الخادم — لا الهاتف، كما في كل
شاشة أخرى.

**يُعيد نوعين من الصفوف** (0093):

1. **عقدة** ملف قائم — مخيم أو برج — بأعدادها.
2. **فندق مثبَّت ليس عقدة** في هذا الموسم، بلا أعداد (`node_id` و`module_id`
   فارغان).

| العمود | المعنى |
| --- | --- |
| `node_id` / `module_id` / `module_name` | **قد تكون فارغة** — فندق ليس عقدة |
| `place_name` | اسم المكان |
| `group_key` | مفتاح ثابت للفلترة — `type:<code>` أو `hotels:<city>`. لا يُعرض |
| `group_ar` / `group_en` | اسم المجموعة باللغتين — القارئ يختار، والدالّة لا تعلم |
| `lat` / `lng` | من `node_location()` (§0087، ووُسِّعت في 0091 و0092) |
| `posted` | من يحمل منصباً هنا — **قوام** المكان |
| `present` | من سجّل وصوله خلال **١٢ ساعة** — **واقعه** |
| `open_incidents` | بلاغات غير مغلقة معلّقة على هذه العقدة |

**تحذير على الترقية:** إضافة الأعمدة الثلاثة تغيّر شكل الصفّ، و`create or
replace` لا يبدّله — أعمدة `OUT` جزء من هويّة الدالّة. لذلك 0093 يبدأ بـ
`drop function if exists season_map(uuid)`، كما فعل 0080 و0084 قبله.

### 31.1a المجموعات — أربع، وليست مكتوبة في أي مكان

مخيمات منى · مخيمات عرفات · فنادق مكة · فنادق المدينة. **تنبثق من البيانات**:
مكانٌ مستواه يسحب من قائمة الفنادق يُجمَّع بـ**مدينة الفندق** (حقل `city`
المرجعي، §0019)، وما عداه بملفّه. مجموعة خامسة تظهر يوم توجد خامسة، بلا تعديل.

**العميل يحفظ المُخفيّ لا المعروض** — فمجموعة تظهر لاحقاً تصل **مرئية**. حفظ
المعروض يجعل كل جديد خفيّاً حتى ينتبه أحد لغيابه.

### 31.1b عيبان كانا يُسقطان الفنادق كلها

**البرج لا عنوان له، لأن البرج هو الفندق** (0092). مستوى البرج لا يعلن حقل موقع؛
يسحب من قائمة الفنادق، والعنوان صفةٌ للفندق (`location_url` على البيانات
المرجعية). و`node_location()` كانت تقرأ بيانات العقدة وحدها — فقُرِئ كل برج كمكان
بلا موقع وأُسقط **بلا كلمة**. صارت تقرأ الاثنين، وقيمة العقدة تفوز حين توجد.

**وفنادق المدينة ليست عُقداً إطلاقاً** (0093). ملف المدينة مستواه الوحيد «شركة
الخدمة» — شركة لا مكان. فالفندق بيانات مرجعية وحسب، ولم يكن ليظهر مهما أُحسن
تثبيته. ولذلك النوع الثاني من الصفوف، مُضيَّقاً بـ«ليس عقدة أصلاً» حتى لا يُرسم
فندق مكة مرّتين ويُعدّ أهله مرّة.

**ما يُستبعد ولماذا:**
- **المستويات غير المكانية** (`is_place = false`، §0089). القطاع ترتيب على ورق
  بلا بوابة ولا إحداثيات؛ رسمه يضع علامة على فكرة.
- **العقد بلا موقع**: `node_location` لا تُعيد صفاً، و`cross join lateral`
  يُسقطها. مكان بلا إحداثيات لا يُرسم، وتخمين إحداثيات له أسوأ من تركه.
- **الملفات المنتهية** (`ends_on < today`). الخريطة عن الموسم كما يُدار.

### 31.1c أشكال روابط الخرائط (0091)

`node_location()` كانت تقرأ شكلين: `?q=lat,lng` و`@lat,lng`. وفاتها الشكل الذي
يُنتجه المدير غالباً: زرّ «مشاركة» في خرائط Google يعطي `maps.app.goo.gl` بلا
إحداثيات إطلاقاً، وتتبُّعه ينتهي إلى:

```
https://www.google.com/maps/search/21.424128,+39.896510?entry=tts&…
```

الزوج في **المسار** لا في معامل، وبينهما `+`. فمكانٌ ثُبِّت من رابط مشاركة كان
يُقرأ كمكان بلا موقع — و`null` هنا لا يُميَّز عن حقل لم يملأه أحد.

**والعميل يحلّ الرابط المختصر عند اللصق ويخزّن الشكل القانوني** `?q=lat,lng`،
فلا تعتمد القاعدة على شكل روابط Google، وتقرأ الموقع دون أن تتبع شيئاً.

### 31.2 البلاغات ليست هنا

طبقة ثانية على الخريطة نفسها، مصدرها `incidents_list` (§30) بإحداثياته هو.
**عمداً:** البلاغ يقع حيث كان المُبلِّغ واقفاً، وهو كثيراً ما ليس مكاناً يعرفه
هذا الملف أصلاً. حافلة متعطلة على طريق عرفات هي الحالة بعينها، وتعليقها على أقرب
مخيم يرسم العلامة حيث لا يحتاج أحد أن يذهب.

ويُجلَب **مستقلاً ويُسمح له بالفشل وحده**: من يرى الخريطة لا يلزم أن يحمل
`incidents.receive`، وخريطة ترفض الرسم لأنه لا يحملها خريطة تعاقبه على ما ليس هو.

### 31.3 التزام الخادم

**تضييق الصفوف مُعاد داخل الدالة**، لأن `security definer` لا يرث RLS. القاعدة:
يرى المستخدم أماكن الملفات التي هو **عضو فيها**، ويرى الجميع إن كان `is_admin()`
أو يحمل `modules.view_all`. **الخريطة يجب ألّا تصير طريقاً لمعرفة قوام ملفات لا
يستطيع فتحها.**

---

## ملحق أ — خريطة الاستبدال السريعة

| Supabase الحالي                                                                            | البديل في هذا المستند |
| ------------------------------------------------------------------------------------------ | --------------------- |
| `auth.signUp / signInWithPassword / signInWithIdToken / setSession / signOut / updateUser` | §2                    |
| RPC `my_permissions`                                                                       | §3.2                  |
| RPC `ensure_current_season` / `set_current_season`                                         | §7.1 / §7.4           |
| RPC `assignable_employees`                                                                 | §9.10                 |
| RPC `submit_module_report`                                                                 | §12.3                 |
| RPC `my_module_rating`                                                                     | §13.4                 |
| RPC `copy_reference_items` / `copy_module_sectors`                                         | §14.2 / §14.3         |
| RPC `broadcast_to_module` / `broadcast_to_all`                                             | §16.6 / §16.7         |
| RPC `dashboard_seasons` / `dashboard_stats`                                                | §18                   |
| RPC `audit_events` / `audit_actors` / `log_auth_event`                                     | §23                   |
| RPC `complaints_list` / `complaints_against_me` / `complaint_thread` / `complaints_against` | §24.3 → §24.6         |
| RPC `complaint_targets`                                                                    | §24.6b                |
| RPC `file_complaint` / `reply_to_complaint` / `set_complaint_lock` / `set_complaint_dismissed` | §24.7              |
| RPC `module_task_board` / `set_module_task_state`                                          | §25.4 / §25.5         |
| جداول `module_tasks` / `module_task_status` / `module_task_attachments`                    | §25.3                 |
| RPC `evaluation_forms_list` / `evaluation_form` / `evaluations_list` / `evaluation_sheet`  | §26.7                 |
| RPC `evaluations_about_me` / `evaluations_about` / `evaluation_targets`                   | §26.7                 |
| اختيار المُقيِّم ⇐ `assignable_employees`                                                  | §9.10 و §26.7         |
| RPC `save_evaluation_form` / `assign_evaluations` / `save_evaluation` / `reopen_evaluation` | §26.8                |
| جداول `evaluation_templates` → `evaluation_answers` (ستة)                                 | §26.5                 |
| Edge `admin-create-user` / `admin-delete-user` / `admin-set-password`                      | §5.1 / §5.6 / §5.7    |
| Edge `admin-set-email` (لموظف / للنفس)                                                     | §5.7b / §2.7          |
| Edge `send-notification`                                                                   | §17.3 (داخلي)         |
| Storage (6 buckets + createSignedUrl + upload + remove)                                    | §19 و §24.8           |
| Realtime (stream notifications)                                                            | §20                   |
| RLS + Triggers (0007→0084)                                                                 | §21 كاملاً و §24.9 و §25.6/§25.8 و §26.9/§26.10 |
| طابور الإرسال (لا endpoint — التزامات إعادة التنفيذ)                                       | §27                   |
| تصدير البيانات (لا endpoint — يقرأ عبر ما سبق)                                             | §28                   |
| pg_cron `escalate-missing-reports` + جدول `report_misses` (0086)                           | §29                   |
| جداول `incidents` / `incident_attachments` + دلو سابع (0088)                               | §30                   |
| RPC `season_map` (0090→0093) + `is_place` (0089) + أشكال الروابط (0091/0092)                | §31                   |
| RPC `check_in_here` / `module_presence` + جدول `node_check_ins` (0087/0094)                | §30                   |

## ملحق ب — ما لا يحتاج backend (يبقى في التطبيق)

- الحسابات المحفوظة وتبديلها: التخزين محلي (keystore) — يحتاج فقط §2.4.
- اشتراكات FCM topics: التطبيق يشترك/يلغي بنفسه عبر Firebase SDK؛ الخادم يحتاج
  فقط الالتزام بأسماء الـ topics (§17.3) وبمسار §9.11/`GET /profiles/{id}/assignments`
  لمعرفة ملفات المستخدم (يستخدم التطبيق حالياً استعلامي عضوية خفيفين — يغطيهما
  §11.1 و §11.2 أو endpoint خفيف: `GET /me/module-ids` ⇒ `{ "module_ids": [...] }`
  **يُنصح بإضافته**).
- إعادة حساب الأعمدة المحسوبة في محرر التقارير (تُخزَّن كقيم جاهزة).
- **طابور الإرسال** (`lib/core/offline/`): ملف JSON ونسخ المرفقات على الجهاز، وكشف
  عودة الشبكة عبر `connectivity_plus`. لا جدول ولا endpoint — لكن للخادم التزامات
  تجاهه، وهي في §27.
- **تقارير الأعطال** (Crashlytics): تذهب إلى Firebase مباشرة، لا إلى هذا الـ API.
- **تصدير البيانات** (`lib/features/export/`): يقرأ عبر الاستدعاءات الموثّقة ويبني
  الملف على الجهاز. لا endpoint — لكن التزام السرّية عليه في §28.2.
- مواقيت الصلاة: تُحسب على الجهاز بالكامل (`adhan_dart`) من إحداثيات يقرأها
  `geolocator` وتُخزَّن في `shared_preferences`، مع سقوط إلى مكة عند تعذّر
  الموقع. لا endpoint لها ولا جدول — الخادم لا يعلم بها.
