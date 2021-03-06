//
//  DownloadsViewController.swift
//  Stepic
//
//  Created by Alexander Karpov on 17.11.15.
//  Copyright © 2015 Alex Karpov. All rights reserved.
//

import UIKit
import DownloadButton
import SVProgressHUD

class DownloadsViewController: UIViewController {

    @IBOutlet weak var tableView: StepikTableView!

    var downloading: [Video] = []
    var stored: [Video] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "DownloadTableViewCell", bundle: nil), forCellReuseIdentifier: "DownloadTableViewCell")

        tableView.emptySetPlaceholder = StepikPlaceholder(.emptyDownloads) { [weak self] in
            self?.tabBarController?.selectedIndex = 1
        }
        self.tableView.tableFooterView = UIView()

        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentBehavior.never
        }
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AmplitudeAnalyticsEvents.Downloads.downloadsScreenOpened.send()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchVideos()
    }

    func fetchVideos() {
        stored = []
        downloading = []
        let videos = Video.getAllVideos()

        for video in videos {
            let isVideoLoading = VideoDownloaderManager.shared.get(by: video.id)?.state == .active
            if isVideoLoading {
                guard let task = VideoDownloaderManager.shared.get(by: video.id) else {
                    return
                }

                downloading += [video]
                task.completionReporter = { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.removeFromDownloading(video)
                        self?.addToStored(video)
                    }
                }

                task.failureReporter = { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.removeFromDownloading(video)
                    }
                }
            }
            if video.state == VideoState.cached {
                stored += [video]
            }
        }
//        print("downloading \(downloading.count), stored \(stored.count)")
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showProfile" {
            let dvc = segue.destination
            dvc.hidesBottomBarWhenPushed = true
        }

        if segue.identifier == "showSteps" {
            let dvc = segue.destination as! LessonViewController
            dvc.hidesBottomBarWhenPushed = true

            let step = sender as! Step
            if let lesson = step.managedLesson {
                //TODO : pass unit here!
                dvc.initObjects = (lesson: lesson, startStepId: lesson.steps.index(of: step) ?? 0, context: .lesson)
            }
        }
    }

    func isSectionDownloading(_ section: Int) -> Bool {
        if downloading != [] && stored != [] {
            return section == 0
        }
        return downloading != []
    }

    func askForClearCache(remove: @escaping (() -> Void)) {
        let alert = UIAlertController(title: NSLocalizedString("ClearCacheTitle", comment: ""), message: NSLocalizedString("ClearCacheMessage", comment: ""), preferredStyle: UIAlertControllerStyle.alert)

        alert.addAction(UIAlertAction(title: NSLocalizedString("Remove", comment: ""), style: UIAlertActionStyle.destructive, handler: {
            _ in
            remove()
        }))

        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.cancel, handler: {
            _ in
        }))

        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func clearCachePressed(_ sender: UIBarButtonItem) {
        AnalyticsReporter.reportEvent(AnalyticsEvents.Downloads.clear, parameters: nil)
        askForClearCache(remove: {
            AnalyticsReporter.reportEvent(AnalyticsEvents.Downloads.acceptedClear, parameters: nil)
            SVProgressHUD.show()

            let videos = Video.getAllVideos()

            var shouldBeRemovedCount = videos.count
            for video in videos {
                do {
                    try VideoFileManager().removeVideo(videoId: video.id)
                    video.cachedQuality = nil
                    CoreDataHelper.instance.save()

                    shouldBeRemovedCount -= 1
                } catch { }
            }

            let completed = videos.count - shouldBeRemovedCount
            if shouldBeRemovedCount == 0 {
                UIThread.performUI({SVProgressHUD.showError(withStatus: "\(NSLocalizedString("FailedToRemoveMessage", comment: "")) \(shouldBeRemovedCount)/\(videos.count) \(NSLocalizedString((completed % 10 == 1 && completed != 11) ? "Video" : "Videos", comment: ""))")})
            } else {
                UIThread.performUI({SVProgressHUD.showSuccess(withStatus: "\(NSLocalizedString("RemovedAllMessage", comment: "")) \(completed) \(NSLocalizedString((completed % 10 == 1 && completed != 11) ? "Video" : "Videos", comment: ""))")})
            }

            UIThread.performUI({self.fetchVideos()})
        })
    }

}

extension DownloadsViewController : UITableViewDelegate {

    func showLessonControllerWith(step: Step) {
        self.performSegue(withIdentifier: "showSteps", sender: step)
    }

    func showNotAbleToOpenLessonAlert(lesson: Lesson, enroll: @escaping (() -> Void)) {
        let alert = UIAlertController(title: NSLocalizedString("NoAccess", comment: ""), message: "\(NSLocalizedString("NotEnrolledToCourseMessage", comment: "")) \"\(lesson.managedUnit!.managedSection!.managedCourse!.title)\". \(NSLocalizedString("JoinCourse", comment: ""))?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("JoinCourse", comment: ""), style: .default, handler: {
            _ in
            enroll()
        }))

        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedVideo: Video!
        if isSectionDownloading((indexPath as NSIndexPath).section) {
            selectedVideo = downloading[(indexPath as NSIndexPath).row]
        } else {
            selectedVideo = stored[(indexPath as NSIndexPath).row]
        }

        if let course = selectedVideo.managedBlock?.managedStep?.managedLesson?.managedUnit?.managedSection?.managedCourse {
            let enterDownloadBlock = {
                [weak self] in
                if course.enrolled {
                    self?.showLessonControllerWith(step: selectedVideo.managedBlock!.managedStep!)
                } else {
                    if selectedVideo.managedBlock!.managedStep!.managedLesson!.isPublic {
                        self?.showLessonControllerWith(step: selectedVideo.managedBlock!.managedStep!)
                    } else {
                        self?.showNotAbleToOpenLessonAlert(lesson: selectedVideo.managedBlock!.managedStep!.managedLesson!, enroll: {
                            let joinBlock : (() -> Void) = {
                                [weak self] in
                                UIThread.performUI({
                                    SVProgressHUD.show()
                                })
                                ApiDataDownloader.enrollments.joinCourse(course, delete: false, success: {
                                    UIThread.performUI({SVProgressHUD.showSuccess(withStatus: "")})
                                    self?.showLessonControllerWith(step: selectedVideo.managedBlock!.managedStep!)
                                    }, error: {
                                        status in
                                        UIThread.performUI({SVProgressHUD.showError(withStatus: status)})
                                        UIThread.performUI({
                                            if let navigation = self?.navigationController {
                                                Messages.sharedManager.showConnectionErrorMessage(inController: navigation)
                                            }
                                        })
                                })
                            }
                            if AuthInfo.shared.isAuthorized {
                                joinBlock()
                            } else {
                                if let s = self {
                                    RoutingManager.auth.routeFrom(controller: s, success: {
                                            joinBlock()
                                    }, cancel: nil)
                                }
                            }
                        })
                    }
                }

            }
            enterDownloadBlock()
//            if let user = AuthInfo.shared.user {
//                if user.isGuest {
//                    if let authVC = ControllerHelper.getAuthController() as? AuthNavigationViewController {
//                        authVC.success = {
//                            performRequest ({
//                                ApiDataDownloader.courses.retrieve([course.id], deleteCourses: [course], refreshMode: .Update, success: {
//                                    course in 
//                                    enterDownloadBlock()
//                                    }, failure: {
//                                        _ in
//                                })
//                            })
//                        }
//                        self.presentViewController(authVC, animated: true, completion: nil)
//                    }
//                } else {
//                    enterDownloadBlock()
//                }
//            }
        } else {
            print("Something bad happened")
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension DownloadsViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSectionDownloading(section) {
            return downloading.count
        } else {
            return stored.count
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        if downloading == [] && stored == [] {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
            return 0
        }

        self.navigationItem.rightBarButtonItem?.isEnabled = true
        if downloading != [] && stored != [] {
            return 2
        }
        return 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isSectionDownloading(section) {
            return NSLocalizedString("Downloading", comment: "")
        } else {
            return NSLocalizedString("Completed", comment: "")
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DownloadTableViewCell", for: indexPath) as! DownloadTableViewCell

        if isSectionDownloading((indexPath as NSIndexPath).section) {
            cell.initWith(downloading[(indexPath as NSIndexPath).row], buttonDelegate: self)
            cell.downloadButton.tag = downloading[(indexPath as NSIndexPath).row].id
        } else {
            cell.initWith(stored[(indexPath as NSIndexPath).row], buttonDelegate: self)
            cell.downloadButton.tag = stored[(indexPath as NSIndexPath).row].id
        }

        return cell
    }
}

extension DownloadsViewController {

    func removeFromDownloading(_ video: Video) {
        if let index = downloading.index(of: video) {
            downloading.remove(at: index)
            self.tableView.beginUpdates()
            tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            if downloading.count == 0 {
//                tableView.reloadData()
                tableView.deleteSections(IndexSet(integer: 0), with: .automatic)
            }
            self.tableView.endUpdates()
        }
    }

    func addToStored(_ video: Video) {
        stored += [video]
        self.tableView.beginUpdates()
        if tableView.numberOfSections == 1 && isSectionDownloading(0) {
            tableView.insertSections(IndexSet(integer: 1), with: .automatic)
        }

        tableView.insertRows(at: [IndexPath(row: stored.count - 1, section: (isSectionDownloading(0) ? 1 : 0))], with: .automatic)
        self.tableView.endUpdates()

    }

    func removeFromStored(_ video: Video) {
        if let index = stored.index(of: video) {
            stored.remove(at: index)
            self.tableView.beginUpdates()
            tableView.deleteRows(at: [IndexPath(row: index, section: (isSectionDownloading(0) ? 1 : 0))], with: .automatic)
            if stored.count == 0 {
//                tableView.reloadData()
                tableView.deleteSections(IndexSet(integer: (isSectionDownloading(0) ? 1 : 0)), with: .automatic)
            }
            self.tableView.endUpdates()
        }
    }
}

extension DownloadsViewController : PKDownloadButtonDelegate {

    func getVideoById(_ array: [Video], id: Int) -> Video? {
        let filtered = array.filter({return $0.id == id})
        if filtered.count != 1 {
            print("strange error occured, filtered count -> \(filtered.count) for video with id -> \(id)")
        } else {
            return filtered[0]
        }
        return nil
    }

    func downloadButtonTapped(_ downloadButton: PKDownloadButton!, currentState state: PKDownloadButtonState) {
        switch downloadButton.state {
        case .downloaded:
            if let vid = getVideoById(stored, id: downloadButton.tag) {
                do {
                    try VideoFileManager().removeVideo(videoId: vid.id)
                    removeFromStored(vid)
                } catch {
                    print("error while deleting from the store")
                }
            }
            break
        case .downloading:
            if let vid = getVideoById(downloading, id: downloadButton.tag) {
                guard let task = VideoDownloaderManager.shared.get(by: vid.id) else {
                    return
                }

                task.cancel()
                VideoDownloaderManager.shared.remove(by: vid.id)
                removeFromDownloading(vid)
            }
            break
        case .startDownload, .pending:
            print("Unsupported states")
            break
        }
    }
}
