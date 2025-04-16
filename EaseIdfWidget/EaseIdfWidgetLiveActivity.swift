//
//  EaseIdfWidgetLiveActivity.swift
//  EaseIdfWidget
//
//  Created by Samuel DELIENS on 16/04/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct EaseIdfWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct EaseIdfWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EaseIdfWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension EaseIdfWidgetAttributes {
    fileprivate static var preview: EaseIdfWidgetAttributes {
        EaseIdfWidgetAttributes(name: "World")
    }
}

extension EaseIdfWidgetAttributes.ContentState {
    fileprivate static var smiley: EaseIdfWidgetAttributes.ContentState {
        EaseIdfWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: EaseIdfWidgetAttributes.ContentState {
         EaseIdfWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: EaseIdfWidgetAttributes.preview) {
   EaseIdfWidgetLiveActivity()
} contentStates: {
    EaseIdfWidgetAttributes.ContentState.smiley
    EaseIdfWidgetAttributes.ContentState.starEyes
}
