//
//  GenericList.swift
//  EhPanda
//
//  Created by 荒木辰造 on 2021/07/25.
//

import SwiftUI
import WaterfallGrid

struct GenericList: View {
    private let items: [Manga]?
    private let setting: Setting
    private let loadingFlag: Bool
    private let notFoundFlag: Bool
    private let loadFailedFlag: Bool
    private let moreLoadingFlag: Bool
    private let moreLoadFailedFlag: Bool
    private let fetchAction: (() -> Void)?
    private let loadMoreAction: (() -> Void)?
    private let translateAction: ((String) -> String)?

    init(
        items: [Manga]?,
        setting: Setting,
        loadingFlag: Bool,
        notFoundFlag: Bool,
        loadFailedFlag: Bool,
        moreLoadingFlag: Bool,
        moreLoadFailedFlag: Bool,
        fetchAction: (() -> Void)? = nil,
        loadMoreAction: (() -> Void)? = nil,
        translateAction: ((String) -> String)? = nil
    ) {
        self.items = items
        self.setting = setting
        self.loadingFlag = loadingFlag
        self.notFoundFlag = notFoundFlag
        self.loadFailedFlag = loadFailedFlag
        self.moreLoadingFlag = moreLoadingFlag
        self.moreLoadFailedFlag = moreLoadFailedFlag
        self.fetchAction = fetchAction
        self.loadMoreAction = loadMoreAction
        self.translateAction = translateAction
    }

    var body: some View {
        if loadingFlag {
            LoadingView()
        } else if loadFailedFlag {
            NetworkErrorView(retryAction: fetchAction)
        } else if notFoundFlag {
            NotFoundView(retryAction: fetchAction)
        } else {
            VStack {
                switch setting.listMode {
                case .detail:
                    DetailList(
                        items: items, setting: setting,
                        moreLoadingFlag: moreLoadingFlag,
                        moreLoadFailedFlag: moreLoadFailedFlag,
                        loadMoreAction: loadMoreAction,
                        translateAction: translateAction
                    )
                case .thumbnail:
                    WaterfallList(
                        items: items, setting: setting,
                        moreLoadingFlag: moreLoadingFlag,
                        moreLoadFailedFlag: moreLoadFailedFlag,
                        loadMoreAction: loadMoreAction,
                        translateAction: translateAction
                    )
                }
            }
            .transition(opacityTransition)
            .refreshable {
                fetchAction?()
            }
        }
    }
}

// MARK: DetailList
private struct DetailList: View {
    private let items: [Manga]?
    private let setting: Setting
    private let moreLoadingFlag: Bool
    private let moreLoadFailedFlag: Bool
    private let loadMoreAction: (() -> Void)?
    private let translateAction: ((String) -> String)?

    init(
        items: [Manga]?, setting: Setting,
        moreLoadingFlag: Bool,
        moreLoadFailedFlag: Bool,
        loadMoreAction: (() -> Void)?,
        translateAction: ((String) -> String)? = nil
    ) {
        self.items = items
        self.setting = setting
        self.moreLoadingFlag = moreLoadingFlag
        self.moreLoadFailedFlag = moreLoadFailedFlag
        self.loadMoreAction = loadMoreAction
        self.translateAction = translateAction
    }

    var body: some View {
        List {
            ForEach(items ?? []) { item in
                ZStack {
                    NavigationLink(
                        destination: DetailView(
                            gid: item.gid
                        )
                    ) {}
                    .opacity(0)
                    MangaDetailCell(
                        manga: item,
                        setting: setting,
                        translateAction: translateAction
                    )
                }
                .onAppear {
                    onRowAppear(item: item)
                }
            }
            .transition(opacityTransition)
            if moreLoadingFlag || moreLoadFailedFlag {
                LoadMoreFooter(
                    moreLoadingFlag: moreLoadingFlag,
                    moreLoadFailedFlag: moreLoadFailedFlag,
                    retryAction: loadMoreAction
                )
            }
        }
    }
    private func onRowAppear(item: Manga) {
        if item == items?.last {
            loadMoreAction?()
        }
    }
}

// MARK: WaterfallList
private struct WaterfallList: View {
    @State var gid: String = ""
    @State var isNavLinkActive = false

    private let items: [Manga]?
    private let setting: Setting
    private let moreLoadingFlag: Bool
    private let moreLoadFailedFlag: Bool
    private let loadMoreAction: (() -> Void)?
    private let translateAction: ((String) -> String)?

    private var columnsInPortrait: Int {
        isPadWidth ? 4 : 2
    }
    private var columnsInLandscape: Int {
        isPadWidth ? 5 : 2
    }

    init(
        items: [Manga]?, setting: Setting,
        moreLoadingFlag: Bool,
        moreLoadFailedFlag: Bool,
        loadMoreAction: (() -> Void)?,
        translateAction: ((String) -> String)? = nil
    ) {
        self.items = items
        self.setting = setting
        self.moreLoadingFlag = moreLoadingFlag
        self.moreLoadFailedFlag = moreLoadFailedFlag
        self.loadMoreAction = loadMoreAction
        self.translateAction = translateAction
    }

    var body: some View {
        NavigationLink(
            destination: DetailView(
                gid: gid
            ),
            isActive: $isNavLinkActive
        ) {}
        .opacity(0)
        .frame(height: 0)
        List {
            WaterfallGrid(items ?? []) { item in
                MangaThumbnailCell(
                    manga: item,
                    setting: setting,
                    translateAction: translateAction
                )
                .onTapGesture {
                    gid = item.gid
                    isNavLinkActive.toggle()
                }
            }
            .gridStyle(
                columnsInPortrait: columnsInPortrait,
                columnsInLandscape: columnsInLandscape,
                spacing: 15, animation: nil
            )
            if !moreLoadingFlag && !moreLoadFailedFlag {
                Button {
                    loadMoreAction?()
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.down")
                        Spacer()
                    }
                }
                .foregroundStyle(.tint)
            }
            if moreLoadingFlag || moreLoadFailedFlag {
                LoadMoreFooter(
                    moreLoadingFlag: moreLoadingFlag,
                    moreLoadFailedFlag: moreLoadFailedFlag,
                    retryAction: loadMoreAction
                )
            }
        }
        .listStyle(.plain)
    }
}
