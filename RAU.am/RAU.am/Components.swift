import SwiftUI
import SafariServices
import NetworkLayer

// MARK: - Images

struct RemoteImage: View {
    let url: URL?

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            case .failure:
                Image(systemName: "photo").foregroundColor(.secondary)
            default:
                ProgressView()
            }
        }
    }
}

/// An image cropped to a fixed aspect ratio (or height), with a grey placeholder behind it.
struct CoverImage: View {
    let url: URL?
    var aspect: CGFloat? = nil
    var height: CGFloat? = nil

    var body: some View {
        if let aspect = aspect {
            base.aspectRatio(aspect, contentMode: .fit)
        } else {
            base.frame(height: height)
        }
    }

    private var base: some View {
        Color(.secondarySystemBackground)
            .overlay(RemoteImage(url: url))
            .clipped()
    }
}

// MARK: - Headers / states

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title2.bold())
                .foregroundColor(Theme.navy)
            Spacer()
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.crimson)
            }
        }
        .padding(.horizontal)
    }
}

struct ErrorBanner: View {
    @EnvironmentObject private var app: AppModel
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.orange)
            Text(L10n.errorTitle.text(app.language)).font(.headline)
            Text(message).font(.footnote).foregroundColor(.secondary).multilineTextAlignment(.center)
            Button(L10n.retry.text(app.language), action: retry)
                .buttonStyle(.borderedProminent)
                .tint(Theme.crimson)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct LoadingBlock: View {
    var height: CGFloat = 120
    var body: some View {
        ProgressView().frame(maxWidth: .infinity, minHeight: height)
    }
}

// MARK: - Links (in-app browser)

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

/// A button that opens `url` in an in-app Safari sheet (http/https) or hands it to the system (tel:, mailto:…).
struct WebLinkButton<Label: View>: View {
    let url: URL?
    private let label: () -> Label

    @State private var isPresented = false
    @Environment(\.openURL) private var openURL

    init(url: URL?, @ViewBuilder label: @escaping () -> Label) {
        self.url = url
        self.label = label
    }

    var body: some View {
        Button {
            guard let url = url else { return }
            if ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                isPresented = true
            } else {
                openURL(url)
            }
        } label: {
            label()
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $isPresented) {
            if let url = url { SafariView(url: url).ignoresSafeArea() }
        }
    }
}

// MARK: - Posts (news + anons)

extension Post {
    /// Some anons are only a title pointing to another site (empty description): those open the link instead.
    var hasArticleBody: Bool {
        let text = (description ?? "").replacingOccurrences(of: "<[^>]+>|&nbsp;|\\s", with: "", options: .regularExpression)
        return text.count > 3
    }
}

/// Opens the in-app article when the post has a body, otherwise its website link.
struct PostLink<Content: View>: View {
    let post: Post
    private let content: () -> Content

    init(post: Post, @ViewBuilder content: @escaping () -> Content) {
        self.post = post
        self.content = content
    }

    var body: some View {
        if post.hasArticleBody || (post.url == nil && post.link == nil) {
            NavigationLink {
                ArticleView(post: post)
            } label: {
                content()
            }
        } else {
            WebLinkButton(url: post.link ?? post.url, label: content)
        }
    }
}

struct PostCard: View {
    @EnvironmentObject private var app: AppModel
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CoverImage(url: post.image ?? post.banner, aspect: 16.0 / 9.0)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(app.language.dateString(post.date))
                .font(.caption.weight(.semibold))
                .foregroundColor(Theme.crimson)
            Text(post.title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            if let subtitle = post.subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PostRow: View {
    @EnvironmentObject private var app: AppModel
    let post: Post
    var showsDate = true

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CoverImage(url: post.image ?? post.banner, aspect: 4.0 / 3.0)
                .frame(width: 110)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 4) {
                if showsDate {
                    Text(app.language.dateString(post.date))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.crimson)
                }
                Text(post.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                if let subtitle = post.subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

// MARK: - Toolbar

struct LanguageMenu: View {
    @EnvironmentObject private var app: AppModel

    var body: some View {
        Menu {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    app.language = language
                } label: {
                    if language == app.language {
                        Label(language.nativeName, systemImage: "checkmark")
                    } else {
                        Text(language.nativeName)
                    }
                }
            }
        } label: {
            Label(app.language.shortName, systemImage: "globe")
                .font(.subheadline.weight(.semibold))
        }
    }
}
