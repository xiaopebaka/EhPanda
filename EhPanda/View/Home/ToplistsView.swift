//
//  ToplistsView.swift
//  EhPanda
//
//  Created by 荒木辰造 on R 4/01/08.
//

import SwiftUI
import ComposableArchitecture

struct ToplistsView: View {
    private let store: Store<ToplistsState, ToplistsAction>
    @ObservedObject private var viewStore: ViewStore<ToplistsState, ToplistsAction>
    private let setting: Setting
    private let tagTranslator: TagTranslator

    init(
        store: Store<ToplistsState, ToplistsAction>,
        setting: Setting, tagTranslator: TagTranslator
    ) {
        self.store = store
        viewStore = ViewStore(store)
        self.setting = setting
        self.tagTranslator = tagTranslator
    }

    private var navigationTitle: String {
        let typeDescription = viewStore.type.description.localized
        return ["Toplists".localized, "(\(typeDescription))"].joined(separator: " ")
    }

    var body: some View {
        GenericList(
            galleries: viewStore.filteredGalleries ?? [],
            setting: setting,
            pageNumber: viewStore.pageNumber,
            loadingState: viewStore.loadingState ?? .idle,
            footerLoadingState: viewStore.footerLoadingState ?? .idle,
            fetchAction: { viewStore.send(.fetchGalleries()) },
            loadMoreAction: { viewStore.send(.fetchMoreGalleries) },
            translateAction: { tagTranslator.tryTranslate(
                text: $0, returnOriginal: setting.translatesTags
            ) }
        )
        .jumpPageAlert(
            index: viewStore.binding(\.$jumpPageIndex),
            isPresented: viewStore.binding(\.$jumpPageAlertPresented),
            isFocused: viewStore.binding(\.$jumpPageAlertFocused),
            pageNumber: viewStore.pageNumber ?? PageNumber(),
            jumpAction: { viewStore.send(.performJumpPage) }
        )
        .animation(.default, value: viewStore.jumpPageAlertPresented)
        .searchable(text: viewStore.binding(\.$keyword), prompt: "Filter")
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                viewStore.send(.fetchGalleries())
            }
        }
        .onDisappear {
            viewStore.send(.onDisappear)
        }
        .navigationTitle(navigationTitle)
        .toolbar(content: toolbar)
    }

    private func toolbar() -> some ToolbarContent {
        CustomToolbarItem {
            ToplistsTypeMenu(type: viewStore.type) { type in
                if type != viewStore.type {
                    viewStore.send(.setToplistsType(type))
                }
            }
            ToolbarFeaturesMenu {
                JumpPageButton(pageNumber: viewStore.pageNumber ?? PageNumber()) {
                    viewStore.send(.presentJumpPageAlert)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        viewStore.send(.setJumpPageAlertFocused(true))
                    }
                }
            }
        }
    }
}

// MARK: Definition
enum ToplistsType: Int, Codable, CaseIterable, Identifiable {
    case yesterday
    case pastMonth
    case pastYear
    case allTime
}

extension ToplistsType {
    var id: Int { description.hashValue }

    var description: String {
        switch self {
        case .yesterday:
            return "Yesterday"
        case .pastMonth:
            return "Past month"
        case .pastYear:
            return "Past year"
        case .allTime:
            return "All time"
        }
    }
    var categoryIndex: Int {
        switch self {
        case .yesterday:
            return 15
        case .pastMonth:
            return 13
        case .pastYear:
            return 12
        case .allTime:
            return 11
        }
    }
}
