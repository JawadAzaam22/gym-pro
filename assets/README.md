# الأصول المطلوبة - Gym Pro Athletic Pulse

هذا المجلد مخصص لصور وأيقونات التطبيق حسب DESIGN.md.

## البنية
```
assets/
├── images/
│   ├── logo.png              # لوجو Athletic Pulse (72x72 أو vector)
│   ├── logo_white.png        # نسخة بيضاء للخلفية الداكنة
│   ├── gym_hero.jpg          # صورة خلفية لشاشة Login (اختياري)
│   ├── avatar_placeholder.png # صورة افتراضية للأعضاء (دائرة 48px)
│   └── hall_*.jpg            # صور القاعات (3 صور: hall_a, hall_b, hall_c)
├── icons/
│   ├── dumbbell.svg          # أيقونة حديد
│   ├── crossfit.svg
│   ├── yoga.svg
│   └── qr.svg
└── illustrations/
    ├── empty_users.svg       # رسم فارغ لقائمة الأعضاء
    ├── empty_halls.svg
    └── success_check.svg
```

## قائمة الصور المطلوبة بالتفصيل

| # | الملف | الاستخدام | الحجم المقترح | الحالة |
|---|-------|-----------|---------------|--------|
| 1 | `images/logo.png` | AppBar + Login + Drawer | 512x512 PNG شفاف | **مطلوب** |
| 2 | `images/avatar_placeholder.png` | UsersList, Checkin, Trainee | 200x200 دائرة | **مطلوب** |
| 3 | `images/gym_hero.jpg` | خلفية Login (مع تعتيم) | 1440x900 | اختياري |
| 4 | `images/hall_a.jpg` | HallsList card | 800x400 | اختياري |
| 5 | `images/hall_b.jpg` | HallsList card | 800x400 | اختياري |
| 6 | `images/hall_c.jpg` (سيدات) | HallsList card | 800x400 | اختياري |
| 7 | `icons/dumbbell.svg` | StatCard / KPI | 24x24 | اختياري (حالياً نستخدم Icons) |
| 8 | `illustrations/empty_users.svg` | EmptyState للأعضاء | 200x150 | اختياري |

## كيفية الإضافة

1. ضع الصور في المجلدات أعلاه
2. حدث `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
    - assets/illustrations/
```
3. استخدمها:
```dart
Image.asset('assets/images/logo.png', width: 72)
SvgPicture.asset('assets/icons/dumbbell.svg', color: AppColors.primary)
```

## الوضع الحالي
- لا توجد صور فعلية - التطبيق يستخدم `Icons` و `CircleAvatar` بألوان Athletic Pulse كبديل
- يعمل بدون أصول (لا يحتاج إضافة فورية)
- عند إضافة `logo.png` سيظهر تلقائياً في Login/Drawer بعد تحديث الكود لاستخدام `Image.asset`

## ملاحظات DESIGN.md
- الألوان الداكنة لا تحتاج صور فاتحة
- يفضل SVG للأيقونات للحفاظ على الحدة على كل المقاسات
- الصور المستخدمة يجب أن تكون بجودة عالية مع ضغط WebP لتقليل حجم التطبيق
