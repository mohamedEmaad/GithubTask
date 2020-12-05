//
//  GithubRepositoriesViewController.swift
//  GithubRepositoriesTask
//
//  Created by Mohamed Emad on 12/3/20.
//  Copyright © 2020 Mohamed Emad. All rights reserved.
//

import UIKit

final class GithubRepositoriesViewController: UIViewController {

    @IBOutlet private weak var githubRepositoriesTableView: UITableView!
    @IBOutlet private weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var emptyLabel: UILabel!
    private var githubRepositoryTableViewCellHeight: CGFloat = 69
    private let githubRepoService: GithubRepositoryService
    private var respositories: [Repository] = []

    init(githubRepoService: GithubRepositoryService) {
        self.githubRepoService = githubRepoService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTableView()
        self.addSearchBarToNavigationControllerBar()
        self.getRepositories()
    }

    private func setupTableView() {
        self.githubRepositoriesTableView.dataSource = self
        self.githubRepositoriesTableView.delegate = self
        self.githubRepositoriesTableView.register(GithubRepositoryTableViewCell.nib, forCellReuseIdentifier: GithubRepositoryTableViewCell.identifier)
        self.githubRepositoriesTableView.tableFooterView = UIView()
    }

    private func addSearchBarToNavigationControllerBar() {
        let searchBar: UISearchBar = self.searchBar()
        self.navigationItem.titleView = searchBar
    }

    private func searchBar() -> UISearchBar {
        let searchBar:UISearchBar = UISearchBar()
        searchBar.placeholder = "Enter your search"
        searchBar.autocapitalizationType = .none
        searchBar.searchTextField.backgroundColor = UIColor.lightGray.withAlphaComponent(0.4)
        searchBar.searchTextField.textColor = UIColor.gray
        searchBar.searchTextField.clearButtonMode = .whileEditing
        searchBar.showsCancelButton = true
        searchBar.delegate = self
        return searchBar
    }

    private func getRepositories(with keyword: String? = nil) {
        self.loadingIndicator.show()
        self.githubRepoService.find(criteria: ["keyword": keyword]) { [weak self] (result) in
            switch result {
            case .success(let repos):
                self?.respositories = repos ?? []
                self?.showSuccessView()
            case .error(let errorMessage):
                self?.respositories = []
                self?.showErrorView(with: errorMessage)
            }
            self?.reloadView()
        }
    }

    private func showSuccessView() {
        self.emptyLabel.isHidden = true
    }

    private func showErrorView(with errorMessage: String) {
        self.emptyLabel.isHidden = false
        self.emptyLabel.text = errorMessage
    }

    private func reloadView() {
        self.loadingIndicator.hide()
        self.githubRepositoriesTableView.reloadData()
    }

}

extension GithubRepositoriesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.respositories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let githubRepositoryTableViewCell: GithubRepositoryTableViewCell = tableView.dequeueReusableCell(withIdentifier: GithubRepositoryTableViewCell.identifier, for: indexPath) as? GithubRepositoryTableViewCell else {
            return UITableViewCell()
        }
        let remoteImageLoader: ImageLoader = GithubUserImageLoader(requestHandler: GithubFetcher(headers: nil))
        let imageLoader: ImageLoader = CachedImageLoader(cacheImage: imageCache, remoteImageLoader: remoteImageLoader)
        githubRepositoryTableViewCell.setupView(with: self.respositories[indexPath.row], imageLoader: imageLoader)
        return githubRepositoryTableViewCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let repository: Repository = self.respositories[indexPath.row]
        let singleRepositoryViewController: SingleRepoViewController = SingleRepoViewController(repository: repository)
        self.navigationController?.pushViewController(singleRepositoryViewController, animated: true)
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.githubRepositoryTableViewCellHeight
    }

}

extension GithubRepositoriesViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if (searchBar.text?.count ?? 0) > 1 {
            self.getRepositories(with: searchBar.text)
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        self.getRepositories()
    }

}
