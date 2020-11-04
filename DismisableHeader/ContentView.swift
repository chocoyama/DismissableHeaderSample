//
//  ContentView.swift
//  DismisableHeader
//
//  Created by Takuya Yokoyama on 2020/11/04.
//

import SwiftUI
import Combine
import Introspect

struct ContentView: View {
    struct ScrollState {
        var offsetY: CGFloat = 0
        var contentOffsetY: CGFloat = 0
    }
    
    enum ScrollDirection {
        case up
        case down
    }
    
    @State private var scrollState: ScrollState = .init()
    @ObservedObject private var tableViewDelegate = TableViewDelegate()
    private let headerHeight: CGFloat = 80

    
    var body: some View {
        ZStack(alignment: .top) {
            List {
                ForEach(0..<100) {
                    Text("\($0)")
                }
            }
            .offset(y: headerHeight)
            .padding(.bottom, scrollState.contentOffsetY == 0.0 ? headerHeight - scrollState.contentOffsetY : 0.0)
            .introspectTableView { (tableView) in
                tableView.delegate = tableViewDelegate
            }
            
            Rectangle()
                .fill(Color.blue)
                .frame(height: headerHeight)
                .frame(maxWidth: .infinity)
        }
        .offset(y: scrollState.contentOffsetY)
        .edgesIgnoringSafeArea(.all)
        .onReceive(
            tableViewDelegate
                .$contentOffsetY
                .compactMap {
                    let shouldMoveContents = 0 <= $0 && $0 <= (tableViewDelegate.contentHeight - tableViewDelegate.frameHeight)
                    return shouldMoveContents ? $0 : nil
                }
                .scan(scrollState, { (prevState, offsetY) in
                    ScrollState(
                        offsetY: offsetY,
                        contentOffsetY: {
                            let diff = offsetY - prevState.offsetY
                            let isScrollDown = diff > 0
                            if isScrollDown {
                                return max(-headerHeight, prevState.contentOffsetY - abs(diff))
                            } else {
                                return min(0, prevState.contentOffsetY + abs(diff))
                            }
                        }()
                    )
                })
        ) {
            self.scrollState = $0
        }
    }
}

class TableViewDelegate: NSObject, ObservableObject, UITableViewDelegate {
    @Published var contentHeight: CGFloat = 0
    @Published var frameHeight: CGFloat = 0
    @Published var contentOffsetY: CGFloat = 0
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        contentHeight = scrollView.contentSize.height
        frameHeight = scrollView.frame.height
        contentOffsetY = scrollView.contentOffset.y
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
