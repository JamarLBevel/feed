import UIKit
import AVFoundation
import Firebase
import SideMenu


class feed_one_CollectionViewController: UICollectionViewController, UICollectionViewDataSourcePrefetching {
   let menu = SideMenuNavigationController(rootViewController: MenuTableViewController())
    var lastDoc : QueryDocumentSnapshot!
    var comment_lastDoc : QueryDocumentSnapshot!
    var posts : [video] = [video]()
    var comments : [comment_struct] = [comment_struct]()
    var the_comment = ""
    var profile_pic : URL?
    var userName = ""
    var uid_forcomment = ""
    var db = Firestore.firestore()
    var urlPass : String = ""
    var doc_id_pass = ""
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    let avPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer!
    var slideupview = UITableView()
    var addComment = UITextView()
    var thekeyboardHeight = CGFloat()
    override func viewDidLoad() {
        super.viewDidLoad()
        //seting up the collection view - feed
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: self.view.frame.width, height: self.view.frame.height)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.collectionViewLayout = layout
        collectionView.isPagingEnabled = true
        self.collectionView.register(UINib(nibName: "videoCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: videoCollectionViewCell().identifer_cell)
        collectionView.backgroundColor = .black
        getData()
       // side bar menu - which is going to change to a tab bar
        let gesture = SideMenuNavigationController(rootViewController: MenuTableViewController())
        gesture.leftSide = true
        SideMenuManager.default.rightMenuNavigationController = gesture
        SideMenuManager.default.addScreenEdgePanGesturesToPresent(toView: self.view , forMenu: .right)
        gesture.presentationStyle = .menuSlideIn
        collectionView.prefetchDataSource = self
        addComment.delegate = self
        //setting up the comments - table view
        slideupview.isScrollEnabled = true
        slideupview.delegate = self
        slideupview.dataSource = self
        slideupview.register(UINib(nibName: "comment_TableViewCell", bundle: nil), forCellReuseIdentifier: comment_TableViewCell().id)
        slideupview.backgroundColor = .black
        
    }
   
  
    
    
    func lucidity2(){
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {return}
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {
            return}
        captureSession.addInput(input)
        captureSession.startRunning()
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.insertSublayer(previewLayer, at: 0)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight
        photoOutput.isHighResolutionCaptureEnabled = true
        guard captureSession.canAddOutput(photoOutput) else {return }
        captureSession.sessionPreset = .photo
        captureSession.addOutput(photoOutput)
        captureSession.commitConfiguration()
        previewLayer.connection?.preferredVideoStabilizationMode = .cinematicExtended
        
        let depthData = AVCaptureDepthDataOutput()
        depthData.isFilteringEnabled = true
    
        captureSession.sessionPreset = AVCaptureSession.Preset.hd4K3840x2160
   
        configureCameraForHighestFrameRate(device: captureDevice)
    }
    func configureCameraForHighestFrameRate(device: AVCaptureDevice) {
        
        var bestFormat: AVCaptureDevice.Format?
        var bestFrameRateRange: AVFrameRateRange?

        for format in device.formats {
            for range in format.videoSupportedFrameRateRanges {
                if range.maxFrameRate > bestFrameRateRange?.maxFrameRate ?? 0 {
                    bestFormat = format
                    bestFrameRateRange = range
                }
            }
        }
        
        if let bestFormat = bestFormat,
           let bestFrameRateRange = bestFrameRateRange {
            do {
                try device.lockForConfiguration()
                
                // Set the device's active format.
                device.activeFormat = bestFormat
                
                // Set the device's min/max frame duration.
                let duration = bestFrameRateRange.minFrameDuration
                device.activeVideoMinFrameDuration = duration
                device.activeVideoMaxFrameDuration = duration
                
                device.unlockForConfiguration()
            } catch {
                // Handle error.
            }
        }
    }
   
 
    
    // MARK: UICollectionViewDataSource

    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return self.posts.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell : videoCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: videoCollectionViewCell().identifer_cell, for: indexPath) as! videoCollectionViewCell
        
        DispatchQueue.main.async {
            cell.video_url = self.posts[indexPath.row].video
            //cell.contentView.backgroundColor = .purple
            cell.contentView.layer.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
            cell.video_view.layer.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
            cell.playVideo()
        }
        self.doc_id_pass = self.posts[indexPath.row].doc_id
        cell.comments.addTarget(self, action: #selector(comment), for: .touchUpInside)
        return cell
    }
  
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == posts.count - 1 {
           
            updateData()
            print("getting new data")
             
            }
        
    }
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let cell : videoCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: videoCollectionViewCell().identifer_cell, for: indexPath) as! videoCollectionViewCell
        if cell.playerQ.rate != 0 {
            cell.playerQ.pause()
        }
    print("cell has left the screen")
        if self.posts.count == 15 {
            posts.removeFirst(5)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
    }

    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        

    }
  

    
    
    func getData() {
        
        db.collection("posts").order(by: "timestamp").limit(to: 5).getDocuments { querySnapshot, err in
            if let err = err {
            print("Error getting documents: \(err)")
        } else {
            for document in querySnapshot!.documents {
                
                let fileUrl = document.data()["theUrl"] as? String ?? ""
                let url = URL(string: fileUrl)
                let title = document.data()["videoTitle"] as? String ?? ""
                let videoTitle = title
                let id = document.documentID
                self.posts.append(video(video: url, title: videoTitle, doc_id: id))
                self.collectionView.reloadData()
                self.lastDoc = querySnapshot?.documents.last
                    }
                }
            }
        }
    func updateData(){
        db.collection("posts").order(by: "timestamp", descending: false).start(afterDocument: lastDoc).limit(to: 5).getDocuments { wuerySnapshot, err in
            if let err = err {
                print(err)
            
            }
            else {
                for documents2 in wuerySnapshot!.documents {
                    let fileUrl = documents2.data()["theUrl"] as? String ?? ""
                   let url = URL(string: fileUrl)
                    let title = documents2.data()["videoTitle"] as? String ?? ""
                    let videoTitle = title
                    let id = documents2.documentID
                    self.posts.append(video(video: url, title: videoTitle, doc_id: id))
                    self.lastDoc = wuerySnapshot?.documents.last
                    self.collectionView.reloadData()
                    print("new data loading")
                    print(self.posts.count)
                }
            }
           
        }
    }
    
}

extension feed_one_CollectionViewController : UITableViewDelegate , UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let comment_cell : comment_TableViewCell = tableView.dequeueReusableCell(withIdentifier: "comment_TableViewCell", for: indexPath) as! comment_TableViewCell
        if comments.count != 0 {
            comment_cell.contentView.backgroundColor = .black
            comment_cell.backgroundColor = .black
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 600
            comment_cell.comment.text = self.comments[indexPath.row].comment
        comment_cell.user_name.text = self.comments[indexPath.row].user
            if self.comments[indexPath.row].profilePic != nil {
        if let p = self.comments[indexPath.row].profilePic {
        URLSession.shared.dataTask(with: p) { data, response, err in
            if err == nil {
            comment_cell.profile_pic.image = UIImage(data: data!)
            }
            else {
                print(err?.localizedDescription ?? "")
                }
            }
        }
    }
}
        return comment_cell
    
    }
}
