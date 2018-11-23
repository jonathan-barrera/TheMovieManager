//
//  MovieDetailViewController.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class MovieDetailViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var watchlistBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var favoriteBarButtonItem: UIBarButtonItem!
    
    var movie: Movie!
    
    var isWatchlist: Bool {
        return MovieModel.watchlist.contains(movie)
    }
    
    var isFavorite: Bool {
        return MovieModel.favorites.contains(movie)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = movie.title
        
        imageView.image = UIImage(named: "PosterPlaceholder")
        
        toggleBarButton(watchlistBarButtonItem, enabled: isWatchlist)
        toggleBarButton(favoriteBarButtonItem, enabled: isFavorite)
        
        // Load the poster image
        loadPosterImage()
    }
    
    func loadPosterImage() {
        if let posterPath = self.movie.posterPath {
            TMDBClient.downloadPosterImage(posterPath: posterPath) {
                [weak self] (data, error) in
                if let data = data {
                    let image = UIImage(data: data)
                    self?.imageView.image = image
                }
            }
        }
    }
    
    @IBAction func watchlistButtonTapped(_ sender: UIBarButtonItem) {
        TMDBClient.markWatchlist(mediaType: "movie", mediaId: movie.id, watchlist: isWatchlist) {
            (success, error) in
            if success {
                if (self.isWatchlist) {
                    MovieModel.watchlist = MovieModel.watchlist.filter() {$0 != self.movie}
                } else {
                    MovieModel.watchlist.append(self.movie)
                }
                self.toggleBarButton(self.watchlistBarButtonItem, enabled: self.isWatchlist)
            }
        }
    }
    
    @IBAction func favoriteButtonTapped(_ sender: UIBarButtonItem) {
        TMDBClient.markFavorite(mediaType: "movie", mediaId: movie.id, favorite: isFavorite) {
            (success, error) in
            if success {
                if (self.isFavorite) {
                    MovieModel.favorites = MovieModel.favorites.filter() {$0 != self.movie}
                } else {
                    MovieModel.favorites.append(self.movie)
                }
                self.toggleBarButton(self.favoriteBarButtonItem, enabled: self.isFavorite)
            }
        }
    }
    
    func toggleBarButton(_ button: UIBarButtonItem, enabled: Bool) {
        if enabled {
            button.tintColor = UIColor.primaryDark
        } else {
            button.tintColor = UIColor.gray
        }
    }
    
    
}
