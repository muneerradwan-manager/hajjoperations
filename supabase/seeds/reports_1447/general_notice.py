# -*- coding: utf-8 -*-
"""Publish one written report, so the general kind can be seen.

    export SUPABASE_SERVICE_KEY=sb_secret_...
    python supabase/seeds/reports_1447/general_notice.py --apply

A real notice rather than a demonstration of the widget set: التعليمات العامة
لحجاج البعثة is the sort of thing the Administration actually posts, and it
happens to need every block there is — headings to divide it, prose to explain,
a numbered list for steps that have an order, bullets for things that do not, a
table for the numbers, a link, a code to scan, and a note for the one line
nobody should skim past.

GENERAL, with no season: instructions of this kind are true until they are
rewritten, which is the case `season_id is null` exists for. It carries no
number, which is the other thing worth seeing — the field is optional and half
of what gets published has none.

Rebuilt from scratch on each run, so it is safe to repeat.
"""
import os, sys
from urllib.parse import quote

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'decisions_1447'))
import sbx  # noqa: E402

APPLY = '--apply' in sys.argv
TITLE = 'التعليمات العامة لحجاج بعثة الحج السورية'

BLOCKS = [
    ('heading', {'text': 'قبل التوجّه إلى المشاعر'}),
    ('paragraph', {'text':
        'تبدأ رحلة المشاعر بالتوجّه إلى منى يوم التروية، وتنتهي بالنفرة من '
        'منى بعد أيام التشريق. هذه التعليمات تُقرأ قبل المغادرة، ويحتفظ بها '
        'الحاج معه طوال الأيام الخمسة.'}),
    ('numbers', {'items': [
        'احمل بطاقة نسك وسوار المعصم طوال الوقت، ولا تنزعهما عند النوم.',
        'تأكد من رقم مخيمك ورقم خيمتك قبل مغادرة الفندق، واحفظهما.',
        'ضع حقيبة صغيرة فيها الدواء والماء والمظلّة، واترك الباقي في الفندق.',
        'اتفق مع مشرف برجك على نقطة لقاء إن انقطع الاتصال.',
    ]}),
    ('note', {'text':
        'من فقد سواره أو بطاقته يراجع مشرف المخيم فوراً — لا تنتظر حتى موعد '
        'التفويج.'}),

    ('divider', {}),
    ('heading', {'text': 'الإعاشة في المشاعر'}),
    ('subheading', {'text': 'ما يُقدَّم، ومتى'}),
    ('paragraph', {'text':
        'تُقدَّم الوجبات في المخيمات وفق الجدول أدناه. الوجبة الجافة تُسلَّم '
        'في العبوة، والساخنة تُقدَّم في وقتها ولا تُخزَّن.'}),
    ('table', {
        'columns': ['اليوم', 'الوجبة', 'نوعها', 'التوقيت'],
        'rows': [
            ['8 ذي الحجة - تروية', 'غداء', 'جافة', 'من الساعة 13:00 إلى الساعة 17:00'],
            ['8 ذي الحجة - تروية', 'عشاء', 'جافة', 'من الساعة 19:00 إلى الساعة 22:00'],
            ['9 ذي الحجة - عرفات', 'فطور', 'جافة', 'من الساعة 6:00 إلى الساعة 9:00'],
            ['9 ذي الحجة - عرفات', 'غداء', 'ساخنة', 'من الساعة 13:00 إلى 16:00'],
        ],
    }),
    ('paragraph', {'text':
        'التفاصيل الكاملة لكل يوم ومكوّنات كل وجبة منشورة في تقريري «مواعيد '
        'تقديم الوجبات» و«مكونات الوجبات».'}),

    ('divider', {}),
    ('heading', {'text': 'عند الحاجة'}),
    ('bullets', {'items': [
        'مشرف المخيم — أول من يُراجَع في كل ما يخصّ السكن والإعاشة.',
        'النقطة الطبية داخل المخيم، وهي مفتوحة على مدار الساعة.',
        'مشرف القطاع، لما لا يُحلّ في المخيم.',
        'غرفة العمليات المشتركة، للحالات الطارئة وحدها.',
    ]}),
    ('url', {
        'url': 'https://syrianhajj.org',
        'label': 'موقع بعثة الحج السورية',
    }),
    ('qr', {
        'value': 'https://syrianhajj.org',
        'label': 'امسح للوصول إلى الموقع ورقم الطوارئ',
    }),
    ('note', {'text':
        'الشكاوى تُقدَّم عبر صندوق الشكاوى في الفندق أو النموذج الإلكتروني، '
        'وتُدرس جميعها — بما فيها ما يُقدَّم بعد العودة.'}),
]


def main():
    types = {t['code']: t for t in sbx.select('report_types')}
    t = types.get('general')
    if t is None:
        raise SystemExit('the `general` report type is not there — run 0069')

    print(f'{TITLE}')
    print(f'  type: general | season: (none — general) | number: (none)')
    print(f'  {len(BLOCKS)} blocks:')
    for kind, data in BLOCKS:
        summary = (
            data.get('text')
            or data.get('label')
            or (f"{len(data.get('items', []))} items" if data.get('items') else '')
            or (f"{len(data.get('columns', []))}×{len(data.get('rows', []))}"
                if data.get('columns') else '—')
        )
        print(f'    {kind:11} {str(summary)[:58]}')

    if not APPLY:
        print('\nDRY RUN — nothing written. Re-run with --apply.')
        return

    # Percent-encoded: the title is Arabic and has spaces, and a raw space in
    # a request line is not a URL at all.
    for old in sbx.select(
        'reports',
        f"select=id&report_type_id=eq.{t['id']}&title=eq.{quote(TITLE)}",
    ):
        sbx.delete('reports', f"id=eq.{old['id']}")

    report = sbx.insert('reports', [{
        'report_type_id': t['id'],
        # Null: true whichever season is running, which is what general means.
        'season_id': None,
        'title': TITLE,
        'data': {
            'subtitle': 'تُقرأ قبل التوجّه إلى المشاعر',
            'note': 'يُرجى من مشرفي الأبراج توزيعها على الحجاج قبل يوم التروية.',
        },
        'is_published': True,
    }])[0]

    sbx.insert('report_blocks', [
        {'report_id': report['id'], 'kind': kind, 'data': data,
         'sort_order': i}
        for i, (kind, data) in enumerate(BLOCKS, 1)
    ])
    print(f"\npublished — {len(BLOCKS)} blocks")
    print('reports now:', len(sbx.select('reports', 'select=id')))


if __name__ == '__main__':
    main()
