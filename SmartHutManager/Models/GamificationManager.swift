import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import Foundation
import CoreData

class GamificationManager {
    static let shared = GamificationManager()

    func recalculatePoints(context: NSManagedObjectContext, completion: @escaping () -> Void) {
        let tradesmenFetchRequest: NSFetchRequest<Tradesmen> = Tradesmen.fetchRequest()
        let workOrderFetchRequest: NSFetchRequest<WorkOrder> = WorkOrder.fetchRequest()
        
        context.perform {
            do {
                let tradesmen = try context.fetch(tradesmenFetchRequest)
                let workOrders = try context.fetch(workOrderFetchRequest)
                
                // Reset points
                tradesmen.forEach { $0.workOrderPoints = 0 }
                
                // Assign points based on work orders
                for workOrder in workOrders {
                    guard let assignedTradesmen = workOrder.tradesmen as? Set<Tradesmen> else { continue }
                    for tradesman in assignedTradesmen {
                        tradesman.workOrderPoints += 50
                    }
                }
                
                try context.save()
                completion()
            } catch {
                print("Failed to recalculate points: \(error.localizedDescription)")
                completion()
            }
        }
    }

    // Fetch leaderboard data
    func getLeaderboardData(context: NSManagedObjectContext) -> [String: Int] {
        let fetchRequest: NSFetchRequest<Tradesmen> = Tradesmen.fetchRequest()
        var leaderboard: [String: Int] = [:]

        do {
            let tradesmen = try context.fetch(fetchRequest)
            for tradesman in tradesmen {
                if let name = tradesman.name {
                    leaderboard[name] = Int(tradesman.points + tradesman.workOrderPoints)
                }
            }
        } catch {
            print("Failed to fetch leaderboard data: \(error.localizedDescription)")
        }

        return leaderboard
    }

    // Assign 50 points when a technician is assigned to a work order
    func assignWorkOrderPoints(to user: String, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Tradesmen> = Tradesmen.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", user)

        do {
            let results = try context.fetch(fetchRequest)
            if let tradesman = results.first {
                tradesman.workOrderPoints += 50 // Add 50 points for the work order
                try context.save()
                print("50 points assigned to \(user) for a work order.")
            }
        } catch {
            print("Failed to assign work order points for \(user): \(error.localizedDescription)")
        }
    }

    // Remove 50 points when a work order is deleted or canceled
    func removeWorkOrderPoints(from user: String, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Tradesmen> = Tradesmen.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", user)

        do {
            let results = try context.fetch(fetchRequest)
            if let tradesman = results.first {
                tradesman.workOrderPoints = max(0, tradesman.workOrderPoints - 50) // Remove 50 points, ensure non-negative
                try context.save()
                print("50 points removed from \(user) due to a canceled/deleted work order.")
            }
        } catch {
            print("Failed to remove work order points for \(user): \(error.localizedDescription)")
        }
    }

    // Fetch badges directly from Core Data
    func getBadges(for user: String, context: NSManagedObjectContext) -> [String] {
        let fetchRequest: NSFetchRequest<Tradesmen> = Tradesmen.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", user)

        do {
            let results = try context.fetch(fetchRequest)
            if let tradesman = results.first, let badges = tradesman.badges {
                return badges
            }
        } catch {
            print("Failed to fetch badges for \(user): \(error.localizedDescription)")
        }

        return []
    }

    func addPoints(to user: String, points: Int, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Tradesmen> = Tradesmen.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", user)

        do {
            let results = try context.fetch(fetchRequest)
            if let tradesman = results.first {
                tradesman.points += Int32(points)
                try context.save()
            }
        } catch {
            print("Failed to add points for \(user): \(error.localizedDescription)")
        }
    }

    func earnBadge(for user: String, badge: String, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Tradesmen> = Tradesmen.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", user)

        do {
            let results = try context.fetch(fetchRequest)
            if let tradesman = results.first {
                if tradesman.badges == nil {
                    tradesman.badges = []
                }
                if !(tradesman.badges?.contains(badge) ?? false) {
                    tradesman.badges?.append(badge)
                    try context.save()
                    print("Badge \(badge) added for \(user).")
                }
            }
        } catch {
            print("Failed to assign badge \(badge) to \(user): \(error.localizedDescription)")
        }
    }
}
