//
//  ViewController.swift
//  Dahmakan-help-order
//
//  Created by Thi Huynh on 4/15/17.
//  Copyright © 2017 Nexx. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ViewController: UIViewController {
    
    @IBOutlet weak var itemCollectionView: UICollectionView!
    @IBOutlet weak var pageControll: UIPageControl!
    @IBOutlet weak var helpView: UIView!
    @IBOutlet weak var contactView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    let viewModel = ViewModel()
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.setupUI()
        self.setupBinding()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupBinding() {
        
        //INPUT
        self.refreshButton
            .rx
            .tap
            .bind(to: self.viewModel.refreshPage)
            .addDisposableTo(disposeBag)
        
        self.itemCollectionView
            .rx
            .setDelegate(self)
            .disposed(by: disposeBag)
        
        
        //OUTPUT
        viewModel
            .result
            .debug()
            .bind(to: itemCollectionView.rx.items(cellIdentifier: "ItemCell", cellType: ItemCell.self)) { (row, element, cell) in
                print("Index", row)
                cell.populateData(model: element)
            }
            .disposed(by: disposeBag)
        
        itemCollectionView
            .rx
            .itemSelected
            .subscribe(onNext: { indexPath in
                print(indexPath)
                let cell = self.itemCollectionView.cellForItem(at: indexPath) as! ItemCell
                print("selected item with order id", cell.orderLabel.text ?? "")
            })
            .addDisposableTo(disposeBag)
        
        
        
        viewModel.result
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { orders in
                print("Get data with \(orders.count) items" )
                self.pageControll.numberOfPages = orders.count
                self.pageControll.currentPage = 0
                self.loading.stopAnimating()
                self.loading.isHidden = true
                self.errorLabel.isHidden = orders.count > 0 ? true : false
                self.refreshButton.isHidden = orders.count > 0 ? true : false
                self.itemCollectionView.reloadData()
                
            }, onError:{ error in
                print("Error with ",error.localizedDescription)
                self.pageControll.numberOfPages = 0
            }).addDisposableTo(disposeBag)
        
        self.viewModel.refreshPage.onNext(())
        
        
    }
    
    func setupUI() {
        let nib = UINib(nibName: "ItemCell", bundle: Bundle.main)
        self.itemCollectionView.register(nib, forCellWithReuseIdentifier: "ItemCell")
        self.errorLabel.isHidden = true
        self.refreshButton.isHidden = true
        
        helpView.layer.cornerRadius = 4
        helpView.layer.borderWidth = 0.5
        helpView.layer.borderColor = UIColor.lightGray.cgColor
        
        contactView.layer.cornerRadius = 4
        contactView.layer.borderWidth = 0.5
        contactView.layer.borderColor = UIColor.lightGray.cgColor
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = self.itemCollectionView.frame.size
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        itemCollectionView.setCollectionViewLayout(layout, animated: true)
        
        self.loading.startAnimating()
        
    }
    
}

extension ViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        self.pageControll.currentPage = indexPath.row
    }
}


class ItemCell: UICollectionViewCell {
    
    @IBOutlet weak var orderLabel: UILabel!
    @IBOutlet weak var arrivedAtLabel: UILabel!
    @IBOutlet weak var paidWithLabel: UILabel!
    
    func populateData(model: OrderItem?) {
        if let interval = model?.arrives_at_utc {
            let date = Date(timeIntervalSince1970: interval)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "hh:mm a"
            dateFormatter.timeZone =  NSTimeZone.local
            self.arrivedAtLabel.text = dateFormatter.string(from: date)
        }
        if let orderId = model?.order_id {
            self.orderLabel.text = "#\(orderId)"
        }
        
        if let paidWith = model?.paid_with {
            self.paidWithLabel.text = paidWith
        }
    }
    
    override func awakeFromNib() {
        self.layer.cornerRadius = 4
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.clipsToBounds = false
    }
    
}


