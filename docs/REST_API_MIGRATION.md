# مواصفات REST API — خطة الاستبدال الكامل لـ Supabase

> **الغرض:** هذا المستند هو المرجع التعاقدي بين تطبيق Flutter وفريق الـ Backend في حال
> الانتقال من Supabase إلى REST API مخصص. تم استخراجه من **الكود الفعلي** للتطبيق
> (كل استدعاء `supabase.from / rpc / storage / functions / auth` موجود في المشروع)
> ومن ملفات الـ migrations (`supabase/migrations/0001 → 0073`).
>
> **تاريخ الإعداد:** 2026-07-31 — فرع `operational-files`.
> **آخر تحديث:** 2026-08-01 — إضافة سجل الأحداث (migration 0077): جدول
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
15. [التقارير المركزية Reports](#15-التقارير-المركزية-reports)
16. [الإشعارات Notifications](#16-الإشعارات-notifications)
17. [أجهزة الدفع Push / Device Tokens](#17-أجهزة-الدفع-push--device-tokens)
18. [لوحة المعلومات Dashboard](#18-لوحة-المعلومات-dashboard)
19. [الملفات والتخزين Storage](#19-الملفات-والتخزين-storage)
20. [البث اللحظي Realtime](#20-البث-اللحظي-realtime)
21. [منطق الخادم الإلزامي (بديل RLS / Triggers)](#21-منطق-الخادم-الإلزامي)
22. [قاموس الأخطاء](#22-قاموس-الأخطاء)
23. [سجل الأحداث Audit Log](#23-سجل-الأحداث-audit-log)

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

توجد **متطلبات مسبقة** بين الصلاحيات (جدول `permission_prerequisites`): لا يجوز منح
صلاحية دون أساسها (مثال: `modules.members` تتطلب `employees.view`)، وسحب الأساس
يسحب توابعه تلقائياً (§21.4).

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
  "job_title": { "name": "طبيب", "name_en": "Physician" },
  "gender": "male",
  "mission_type": "administrative",
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
  "mission_type": "administrative",
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
GET /job-titles?active=true
```

**Response:** `[{ "id": "uuid", "name": "طبيب", "name_en": "Physician", "is_active": true, "sort_order": 1 }]`

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
  "mission_type": "administrative",
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
  "mission_type": "... | null",
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

### 11.5 مهام عضو

```
PUT /members/{memberId}/tasks
```

**Request:** `{ "task_ids": ["uuid", ...] }` — نفس منطق diff (الباقي لا يُلمس
حفاظاً على من أسند ومتى). **Response:** `204`.

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

## 15. التقارير المركزية Reports

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
    "by_mission": [{ "key": "administrative", "count": 120 }],
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
| reference data   | حساب فعّال (+ `syrian_cities` و `job_titles` لأي مُصادَق)                                       | reference.\*                        |
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
| Edge `admin-create-user` / `admin-delete-user` / `admin-set-password`                      | §5.1 / §5.6 / §5.7    |
| Edge `admin-set-email` (لموظف / للنفس)                                                     | §5.7b / §2.7          |
| Edge `send-notification`                                                                   | §17.3 (داخلي)         |
| Storage (5 buckets + createSignedUrl + upload + remove)                                    | §19                   |
| Realtime (stream notifications)                                                            | §20                   |
| RLS + Triggers (0007→0076)                                                                 | §21 كاملاً            |

## ملحق ب — ما لا يحتاج backend (يبقى في التطبيق)

- الحسابات المحفوظة وتبديلها: التخزين محلي (keystore) — يحتاج فقط §2.4.
- اشتراكات FCM topics: التطبيق يشترك/يلغي بنفسه عبر Firebase SDK؛ الخادم يحتاج
  فقط الالتزام بأسماء الـ topics (§17.3) وبمسار §9.11/`GET /profiles/{id}/assignments`
  لمعرفة ملفات المستخدم (يستخدم التطبيق حالياً استعلامي عضوية خفيفين — يغطيهما
  §11.1 و §11.2 أو endpoint خفيف: `GET /me/module-ids` ⇒ `{ "module_ids": [...] }`
  **يُنصح بإضافته**).
- إعادة حساب الأعمدة المحسوبة في محرر التقارير (تُخزَّن كقيم جاهزة).
