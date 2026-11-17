//
//  StepComplicationsBundle.swift
//  StepComplications
//
//  Created by Siegmund Murer on 11.11.26.
//

import WidgetKit
import SwiftUI

@main
struct StepComplicationsBundle: WidgetBundle {
    var body: some Widget {
        StepComplications()
        BigNumberStepWidget()
        RemainingStepsWidget()
    }
}
