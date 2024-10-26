//
//  DateHelper.swift
//  irl
//
//  Created by Elijah Arbee on 9/20/24.
//
// DateHelper.swift
import Foundation

final class DateHelper {
    
    // Singleton instance to avoid recreating DateFormatters multiple times
    static let shared = DateHelper()
    
    private let dateFormatter: DateFormatter
    private let timeFormatter: DateFormatter
    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        
        timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
    }
    
    // Method to format the date for day separator
    func formatForSeparator(date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    // Method to format the time for chat messages
    func formatTime(date: Date) -> String {
        return timeFormatter.string(from: date)
    }
}
