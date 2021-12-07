//
//  ViewController.swift
//  Fibonacci
//
//  Created by Aryaman Sharda on 12/6/21.
//

import UIKit

final class FibonacciCalculator {
    private var sequenceCache = [Int: UInt64?]()
    var maxFibonacciPositionReached = false
    
    private enum FibonacciError: LocalizedError {
        case overflow

        var errorDescription: String? {
            switch self {
            case .overflow:
                return "Maximum Swift UInt64 value reached."
            }
        }
    }
    
    func nthFibonacciNumber(_ n: Int) throws -> UInt64? {
        if n == 0 || n == 1 {
            return UInt64(n)
        } else {
            guard !maxFibonacciPositionReached else { return nil }
            
            let nMinusOneFibonacci = try sequenceCache[n - 1] as? UInt64 ?? nthFibonacciNumber(n - 1)
            sequenceCache[n - 1] = nMinusOneFibonacci
            
            let nMinusTwoFibonacci = try sequenceCache[n - 2] as? UInt64 ?? nthFibonacciNumber(n - 2)
            sequenceCache[n - 2] = nMinusTwoFibonacci
                    
            guard let nMinusOneFibonacci = nMinusOneFibonacci, let nMinusTwoFibonacci = nMinusTwoFibonacci else {
                return nil
            }
                
            let (sum, didOverflow) = nMinusOneFibonacci.addingReportingOverflow(nMinusTwoFibonacci)
            
            if didOverflow {
                maxFibonacciPositionReached = true
                throw FibonacciError.overflow
            }
            
            return sum
        }
    }
}

final class FibonacciTableViewController: UITableViewController {
    
    // MARK: - Properties
    private let fibonaciCalculator = FibonacciCalculator()
    private let serialQueue = DispatchQueue(label: "serial")
    private let pageAmount = 5
    
    private var dataSource = [UInt64]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Compute initial "pageAmount" worth of values in the sequence
        for position in 0..<pageAmount {
            generateFibonacciNumber(at: position)
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Private Methods
    private func generateFibonacciNumber(at position: Int) {
        do {
            if let nextFibonacciNumber = try fibonaciCalculator.nthFibonacciNumber(position) {
                dataSource.append(nextFibonacciNumber)
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.presentDefaultErrorAlert(withTitle: "Error", message: error.localizedDescription)
            }
        }
    }
}

// MARK: - UITableView Data Source
extension FibonacciTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FibonacciCell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = "\(dataSource[indexPath.row])"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // If we are within one pageAmount of entries (5) from the end of the UITableView and we
        // haven't hit the maximum value yet, fetch the next pageAmount worth of numbers in the
        // sequence.
        guard indexPath.row + pageAmount >= dataSource.count && !fibonaciCalculator.maxFibonacciPositionReached else {
            return
        }
        
        serialQueue.async { [weak self] in
            guard let dataSource = self?.dataSource, let pageAmount = self?.pageAmount else {
                return
            }

            for position in dataSource.count..<dataSource.count + pageAmount {
                self?.generateFibonacciNumber(at: position)
            }
            
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
}

// MARK: - Extensions
extension UIViewController {
    func presentDefaultErrorAlert(withTitle title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let defaultAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        
        present(alertController, animated: true, completion: nil)
    }
}
