//
//  AppLanguage.swift
//  RAU.am
//
//  Created by artak on 12.11.26.
//  Copyright © 2026 Russian-Armenian University. All rights reserved.
//



import Foundation

/// The three site languages. The API selects the language with the `lang` query parameter.
enum AppLanguage: String, CaseIterable, Identifiable {
    case armenian = "hy"
    case russian = "ru"
    case english = "en"

    var id: String { rawValue }

    /// Value of the API's `lang` parameter.
    /// ru = 1 and en = 2 are confirmed from real API responses; hy = 3 is inferred (the remaining id).
    /// If Armenian content does not appear, change the number here – it is the only place.
    var apiID: Int {
        switch self {
        case .russian: return 1
        case .english: return 2
        case .armenian: return 3
        }
    }

    /// Path segment the website uses for this language (`rau.am/am`, `rau.am/ru`, `rau.am/en`).
    var sitePath: String {
        switch self {
        case .armenian: return "am"
        case .russian: return "ru"
        case .english: return "en"
        }
    }

    var nativeName: String {
        switch self {
        case .armenian: return "Հայերեն"
        case .russian: return "Русский"
        case .english: return "English"
        }
    }

    var shortName: String {
        switch self {
        case .armenian: return "ՀԱՅ"
        case .russian: return "РУС"
        case .english: return "ENG"
        }
    }

    var locale: Locale { Locale(identifier: rawValue) }

    static var deviceDefault: AppLanguage {
        switch Locale.current.language.languageCode?.identifier {
        case "hy": return .armenian
        case "ru": return .russian
        default: return .english
        }
    }

    func dateString(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.wide).year().locale(locale))
    }
}

/// Every fixed UI string, in the three site languages (content itself comes from the API).
enum L10n {
    case home, news, announcements, institutes, menu, pages, language
    case viewAll, details, retry, loading, noData, errorTitle
    case categories, qlInternational, qlMBA, qlPublishing, qlTV, qlValues
    case statInstitutes, statStudents, statPupils, statPostgraduates, statAlumni
    case contacts, followUs, admissionsInfo

    func text(_ language: AppLanguage) -> String {
        let t = translations
        switch language {
        case .english: return t.en
        case .armenian: return t.hy
        case .russian: return t.ru
        }
    }

    private var translations: (en: String, hy: String, ru: String) {
        switch self {
        case .home: return ("Home", "Գլխավոր", "Главная")
        case .news: return ("News", "Նորություններ", "Новости")
        case .announcements: return ("Announcements", "Հայտարարություններ", "Объявления")
        case .institutes: return ("Institutes", "Ինստիտուտներ", "Институты")
        case .menu: return ("Menu", "Մենյու", "Меню")
        case .pages: return ("Pages", "Էջեր", "Страницы")
        case .language: return ("Language", "Լեզու", "Язык")
        case .viewAll: return ("View all", "Դիտել բոլորը", "Смотреть все")
        case .details: return ("Details", "Մանրամասներ", "Подробнее")
        case .retry: return ("Retry", "Կրկնել", "Повторить")
        case .loading: return ("Loading…", "Բեռնվում է…", "Загрузка…")
        case .noData: return ("Nothing here yet", "Տվյալներ չկան", "Пока ничего нет")
        case .errorTitle: return ("Something went wrong", "Ինչ-որ բան սխալ ընթացավ", "Что-то пошло не так")
        case .categories: return ("Quick links", "Կատեգորիաներ", "Категории")
        case .qlInternational: return ("International Department", "Միջազգային բաժին", "Международный отдел")
        case .qlMBA: return ("MBA Programs", "MBA Ծրագրեր", "MBA программы")
        case .qlPublishing: return ("Publishing", "Հրատարակչություն", "Издательство")
        case .qlTV: return ("RAU-TV", "ՌԱՈՒ-TV", "РАУ-TV")
        case .qlValues: return ("RAU Values", "ՀՌՀ արժեքներ", "Ценности РАУ")
        case .statInstitutes: return ("Institutes", "Ինստիտուտ", "Институтов")
        case .statStudents: return ("Students", "Ուսանող", "Студентов")
        case .statPupils: return ("“Usmunq” school pupils", "«Ուսմունք» դպրոցի աշակերտ", "Учеников школы «Ուսմունք»")
        case .statPostgraduates: return ("Postgraduates", "Ասպիրանտ և հայցորդ", "Аспирантов и соискателей")
        case .statAlumni: return ("Alumni", "Շրջանավարտ", "Выпускников")
        case .contacts: return ("Contacts", "Կոնտակտներ", "Контакты")
        case .followUs: return ("Follow us", "Հետևեք մեզ", "Мы в соцсетях")
        case .admissionsInfo: return ("Admissions information", "Տեղեկատվություն դիմորդներին", "Информация для абитуриентов")
        }
    }
}
