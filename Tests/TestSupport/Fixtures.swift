import Foundation

/// JSON payloads shared by unit, integration and end-to-end tests (trimmed copies of real API responses).
public enum Fixtures {
    public static func data(_ json: String) -> Data { Data(json.utf8) }

    public static func date(_ iso: String) -> Date {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: iso) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: iso)!
    }

    /// Wraps a payload in the API envelope: {"data": …, "meta": …?, "success": …, "lang": …}
    public static func envelope(_ payload: String, meta: String? = nil, title: String? = nil, success: Bool = true) -> String {
        let metaPart = meta.map { #""meta": \#($0), "# } ?? ""
        let titlePart = title.map { #""title": "\#($0)", "# } ?? ""
        return #"{"data": \#(payload), \#(metaPart)\#(titlePart)"success": \#(success), "lang": {"id": 2, "code": "en"}}"#
    }

    public static func meta(page: Int = 1, perPage: Int = 10, total: Int, lastPage: Int, hasMore: Bool) -> String {
        #"{"page": \#(page), "per_page": \#(perPage), "total": \#(total), "last_page": \#(lastPage), "has_more": \#(hasMore)}"#
    }

    // MARK: Institutes
    public static let institutesList = """
    [
      {"id": 1, "name": "Institute of International Relations and Socio-Political Science",
       "slug": "sociopolitics", "url": "https://sociopolitics.rau.am"},
      {"id": 2, "name": "Institute of Mathematics and Informatics",
       "slug": "imi", "url": "https://imi.rau.am"}
    ]
    """

    /// A real response copied from the API (full envelope).
    public static let realInstitutesResponse = """
    {
        "data": [
            {"id": 4, "name": "Institute of Biomedicine and Pharmacy", "slug": "ibmp", "url": "https://ibmp.rau.am"},
            {"id": 7, "name": "INSTITUTE OF ECONOMICS AND BUSINESS", "slug": "inecbus", "url": "https://inecbus.rau.am"},
            {"id": 1, "name": "Institute of International Relations and Socio-Political Science", "slug": "sociopolitics", "url": "https://sociopolitics.rau.am"},
            {"id": 6, "name": "Institute of Law", "slug": "il", "url": "https://il.rau.am"},
            {"id": 2, "name": "Institute of Mathematics and Informatics", "slug": "imi", "url": "https://imi.rau.am"},
            {"id": 3, "name": "Institute of Mathematics, Physics and High Technologies", "slug": "impht", "url": "https://impht.rau.am"},
            {"id": 5, "name": "Institute of Media, Advertising and Cinema", "slug": "imrk", "url": "https://imrk.rau.am"},
            {"id": 8, "name": "INSTITUTE OF ORIENTAL STUDIES", "slug": "orient", "url": "https://orient.rau.am"},
            {"id": 11, "name": "Institute of Philology and Intercultural Communication", "slug": "iphilology", "url": "https://iphilology.rau.am"}
        ],
        "success": true,
        "lang": {"id": 2, "code": "en"}
    }
    """

    // Institute detail: response not provided yet – fields are a guess.
    public static let instituteDetail = """
    {
      "id": 1, "name": "Institute of International Relations and Socio-Political Science",
      "slug": "sociopolitics", "url": "https://sociopolitics.rau.am",
      "description": "Founded in 1999.", "address": "123 University Street",
      "email": "info@rau.am", "phone": "+374 60 710000",
      "departments": [{"id": 10, "name": "Political Science"}, {"id": 11, "name": "History"}]
    }
    """
    public static let instituteDetailMinimal = """
    {"id": 2, "name": "Institute of Mathematics and Informatics"}
    """

    // MARK: News
    public static let newsList = """
    [
      {"id": 4533, "group": "news",
       "title": "International Conference “Russian Literature in a Changing World” Opens at RAU",
       "subtitle": "Over the course of two days, participants will present more than 50 papers.",
       "description": "<div>The annual conference opened on October 15.</div>",
       "image": "https://rau.am/uploads/post/image/1792053748_1--1.jpg",
       "banner": "https://rau.am/uploads/post/banner/1792053748_1--1.jpg",
       "date": "2026-10-15T08:42:28+00:00", "event_date": null,
       "permalink": "rus-lit-conf26", "url": "https://rau.am/en/news/rus-lit-conf26", "link": null},
      {"id": 4530, "group": "news", "title": "RAU Hosts the 3rd International Conference",
       "subtitle": null, "description": null, "image": null, "banner": null,
       "date": "2026-10-15T07:20:14+00:00", "event_date": null,
       "permalink": "transform-upr-conf-3", "url": "https://rau.am/en/news/transform-upr-conf-3", "link": null}
    ]
    """
    public static let newsMeta = meta(page: 1, perPage: 10, total: 351, lastPage: 36, hasMore: true)

    public static let newsDetail = """
    {
      "id": 4533, "group": "news",
      "title": "International Conference “Russian Literature in a Changing World” Opens at RAU",
      "subtitle": "Over the course of two days, participants will present more than 50 papers.",
      "description": "<div>The annual conference opened on October 15.</div>",
      "image": "https://rau.am/uploads/post/image/1792053748_1--1.jpg",
      "banner": "https://rau.am/uploads/post/banner/1792053748_1--1.jpg",
      "date": "2026-10-15T08:42:28+00:00", "event_date": null,
      "permalink": "rus-lit-conf26", "url": "https://rau.am/en/news/rus-lit-conf26", "link": null,
      "gallery": [
        {"id": 19440, "url": "https://rau.am/uploads/post/gallery/1792053691_photo_5368488535234648796_w.jpg"},
        {"id": 19441, "url": "https://rau.am/uploads/post/gallery/1792053691_photo_5368488535234648792_w.jpg"}
      ]
    }
    """

    // MARK: Announcements ("anons")
    public static let announcementsList = """
    [
      {"id": 4367, "group": "anons", "title": "XX International Annual Scientific Conference of RAU",
       "subtitle": "Materials can be submitted electronically from September 21 to November 1, 2026",
       "description": "<div>The conference will be held from 30 November to 4 December, 2026.</div>",
       "image": "https://rau.am/uploads/post/image/1789130729_1758106369_1732781949_154.jpg",
       "banner": "https://rau.am/uploads/post/banner/1789130729_1758106369_1732781949_154.jpg",
       "date": "2026-09-21T06:24:52+00:00", "event_date": null,
       "permalink": "conference-2026", "url": "https://rau.am/en/event/conference-2026", "link": null},
      {"id": 3031, "group": "anons", "title": "RAU Department of International Cooperation | Open calls",
       "subtitle": "Staff Mobility & Student Mobility", "description": null,
       "image": "https://rau.am/uploads/post/image/1749467819_computer-2242262_1280.jpg",
       "banner": "https://rau.am/uploads/post/banner/1749467819_computer-2242262_1280.jpg",
       "date": "2025-06-09T11:16:59+00:00", "event_date": null,
       "permalink": "https://dic.rau.am/en/tab-page/3821647162-open-calls",
       "url": "https://dic.rau.am/en/tab-page/3821647162-open-calls", "link": null}
    ]
    """
    public static let announcementsMeta = meta(page: 1, perPage: 20, total: 5, lastPage: 1, hasMore: false)

    /// Announcement detail: assumed to be the post shape (no gallery in this sample).
    public static let announcementDetail = """
    {
      "id": 4367, "group": "anons", "title": "XX International Annual Scientific Conference of RAU",
      "subtitle": "Materials can be submitted electronically from September 21 to November 1, 2026",
      "description": "<div>The conference will be held from 30 November to 4 December, 2026.</div>",
      "image": null, "banner": null, "date": "2026-09-21T06:24:52+00:00", "event_date": null,
      "permalink": "conference-2026", "url": "https://rau.am/en/event/conference-2026", "link": null
    }
    """

    // MARK: Pages
    public static let pagesList = """
    [
      {"id": 39, "title": "Sustainability at Russian-Armenian University", "slug": "sustainability",
       "short_description": null,
       "banner": "https://rau.am/uploads/page/55 (1)7MQ0I0EQvb4Rds31761130561.jpg",
       "url": "https://rau.am/en/content/sustainability",
       "meta_key": null, "meta_description": null, "form_id": null,
       "updated_at": "2026-07-14T05:42:24+00:00"},
      {"id": 34, "title": "Department of International Cooperation", "slug": "international",
       "short_description": "International cooperation is one of top priorities of RAU.",
       "banner": "https://rau.am/uploads/page/international.jpg",
       "url": "https://rau.am/en/content/international",
       "meta_key": "International Cooperation", "meta_description": "Department of International Cooperation",
       "form_id": null, "updated_at": "2026-10-02T13:18:28+00:00"}
    ]
    """
    public static let pagesMeta = meta(page: 1, perPage: 10, total: 15, lastPage: 2, hasMore: true)

    // Page detail: response not provided yet – shape is a guess (list fields + `description`).
    public static let pageDetail = """
    {"id": 39, "title": "Sustainability at Russian-Armenian University", "slug": "sustainability",
     "short_description": null, "banner": null, "url": "https://rau.am/en/content/sustainability",
     "meta_key": null, "meta_description": null, "form_id": null,
     "description": "<p>Our sustainability goals.</p>", "updated_at": "2026-07-14T05:42:24+00:00"}
    """

    // MARK: Menus (tree)
    public static let menusList = """
    [
      {"id": 28, "name": "Discover RAU", "link": null, "url": null, "parent_id": 0, "order": 2, "children": [
        {"id": 133, "name": "RAU Rector", "link": "https://rector.rau.am/en", "url": "https://rector.rau.am/en",
         "parent_id": 28, "order": 1, "children": []},
        {"id": 132, "name": "Information about the educational organization",
         "link": "https://rau.am/en/content/sveden", "url": "https://rau.am/en/content/sveden",
         "parent_id": 28, "order": 3, "children": []}
      ]},
      {"id": 30, "name": "Admissions", "link": null, "url": null, "parent_id": 0, "order": 3, "children": [
        {"id": 55, "name": "Incoming Mobility", "link": "https://rau.am/en/content/incoming-mobility",
         "url": "https://rau.am/en/content/incoming-mobility", "parent_id": 30, "order": 29, "children": []}
      ]}
    ]
    """

    // MARK: Statistics / Courses / Categories
    public static let statisticsList = """
    [{"count": 8, "title": "Институтов"}, {"count": 6039, "title": "Всего обучающихся"}, {"count": 14101, "title": "Выпускников"}]
    """

    public static let coursesList = """
    [
      {"id": 1, "name": "Самообследование", "subtitle": null,
       "image": "https://rau.am/uploads/course/1585513619_index.jfif",
       "link": "https://rau.am/file-content/samoobsledovanie", "url": "https://rau.am/file-content/samoobsledovanie", "order": 1},
      {"id": 15, "name": "Лаборатория цифрового контента", "subtitle": "Digital",
       "image": "https://rau.am/uploads/course/1760625800_3063022.png",
       "link": "https://rau.am/jalinga", "url": "https://rau.am/jalinga", "order": 2}
    ]
    """

    public static let categoriesList = """
    [
      {"id": 1, "name": "Международный отдел",
       "icon": "https://rau.am/uploads/category_menu/1585565061_international-money-transaction-icon-vector-21023017.jpg",
       "link": "https://dic.rau.am/", "url": "https://dic.rau.am/", "order": 1},
      {"id": 15, "name": "РАУ ТВ", "icon": "https://rau.am/uploads/category_menu/1659088932_video-camera-png-icon-5.png",
       "link": "https://tv.rau.am/", "url": "https://tv.rau.am/", "order": 7}
    ]
    """

    // MARK: Errors
    public static let notFoundBody = #"{"error": "not found"}"#
    public static let malformedJSON = #"{"data": {"id": 1, "slug": "about""#           // truncated JSON
    public static let wrongShape = #"{"data": {"id": "not-a-number", "title": "About", "slug": "about"}, "success": true}"#
}
