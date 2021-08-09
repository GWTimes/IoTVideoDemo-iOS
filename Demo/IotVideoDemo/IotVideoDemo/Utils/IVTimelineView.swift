//
//  IVTimelineView.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2020/1/8.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import SnapKit

//MARK: - 时间轴代理协议
protocol IVTimelineViewDelegate: class {
    /// （滚动中）到达某时刻
    /// - Parameters:
    ///   - timelineView: 时间轴对象
    ///   - time: 时间值（UTC时间，不是偏移量）
    func timelineView(_ timelineView: IVTimelineView, didScrollTo time: TimeInterval)

    /// （滚动停止）选中某时刻
    /// - Parameters:
    ///   - timelineView: 时间轴对象
    ///   - item: 时间片段
    ///   - time: 时间值（UTC时间，不是偏移量）
    func timelineView(_ timelineView: IVTimelineView, didSelectItem item: IVTimelineItem?, at time: TimeInterval)
    
    /// 点击选中某日期
    /// - Parameters:
    ///   - timelineView: 时间轴对象
    ///   - time: 日期所在的时间片段
    func timelineView(_ timelineView: IVTimelineView, didSelectDateAt time: IVTime)

    /// 选择模式下选中某时间范围
    /// - Parameters:
    ///   - timelineView: 时间轴对象
    ///   - time: 选择的时间范围
    ///   - longest: 是否达到长可选时间范围
    func timelineView(_ timelineView: IVTimelineView, didSelectRangeAt time: IVTime, longest: Bool)

    /// 数据源
    /// - Parameters:
    ///   - timelineView: 时间轴对象
    ///   - time: 时间片段
    ///   - completionHandler: 数据获取完成回调
    func timelineView(_ timelineView: IVTimelineView, itemsForTimelineAt time: IVTime, completionHandler: @escaping ([IVTimelineItem]?) -> Void)
    
    /// 获取打点日期
    /// - Parameters:
    ///   - timelineView: 时间轴对象
    ///   - time: 时间片段
    ///   - completionHandler: 数据获取完成回调
    func timelineView(_ timelineView: IVTimelineView, markListForCalendarAt time: IVTime, completionHandler: @escaping ([IVCSMarkItem]?) -> Void)
}

// MARK: - 时间轴视图

class IVTimelineView: UIControl {
    
    /// 时间轴事件代理
    weak var delegate: IVTimelineViewDelegate?
       
    /// 视图模型
    var viewModel: IVTimelineViewModel = IVTimelineViewModel(time: .today)
    
    var selectedDateColor: UIColor = .lightGray {
        didSet {
            datelineView.selectedColor = selectedDateColor
        }
    }
        
    private var loadingTimes: [IVTime] = []
    
    // MARK: - UI元素

    private let indicatorLine = IVIndicatorLine()
        
    private var selectView = IVTimelineSelectView().then {
        $0.isHidden = true
    }
    
    private let calendarBtn: UIButton = {
        let btn = UIButton()
        if let img = UIImage(named: "calender_icon") {
            btn.setImage(img, for: .normal)
        } else {
            btn.setTitle("📅", for: .normal)
        }
        btn.backgroundColor = UIColor(white: 0.98, alpha: 1)
        return btn
    }()
    
    /// 日期容器视图
    private let datelineView = IVDatelineView()
    
    /// 时间轴容器视图
    lazy var timeCollView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        let col = UICollectionView(frame: .zero, collectionViewLayout: layout)
        col.register(IVTimelineCell.self, forCellWithReuseIdentifier: "IVTimelineCell")
        col.register(IVTimelineHeaderFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: UICollectionView.elementKindSectionHeader)
        col.register(IVTimelineHeaderFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: UICollectionView.elementKindSectionFooter)
        col.showsHorizontalScrollIndicator = false
        col.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 100, bottom: 0, right: 100)
        col.backgroundColor = UIColor(white: 0.98, alpha: 1)
        col.dataSource = self
        col.delegate   = self
        col.addGestureRecognizer(pinchGesture)
        return col
    }()

    let loadingAnim = UIActivityIndicatorView(style: .gray)
    
    /// 缩放手势
    private lazy var pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchGestureHandler(_:)))
    
    lazy var calendarView: IVCalendarView = {
        let cal = IVCalendarView()
        cal.backgroundColor = .white
        cal.alpha = 0
        cal.currentDate = viewModel.current.date
        return cal
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareView()
        prepareEvent()
        prepareLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        prepareView()
        prepareEvent()
        prepareLayout()
    }
    
    deinit {
        logDebug("timeline view deinit")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
//        layoutIfNeeded()
        
        calendarBtn.isHidden = gIsLandscape
        datelineView.isHidden = gIsLandscape
        if gIsLandscape { calendarView.alpha = 0 }
            
        self.timeCollView.reloadData()
        if viewModel.current.isPlaceholder {
            loadAndDisplaySection(at: viewModel.current.time, scrollToTime: viewModel.pts.value)
        } else {
            scrollToTime(viewModel.pts.value, animated: false)
        }
    }
    
    override var isTracking: Bool {
        return isTimeCollViewInteracting || datelineView.isTracking
    }
    
    var isSelecting: Bool {
        return self.viewModel.state.value == .selecting
    }
}

// MARK: - 私有方法

private extension IVTimelineView {
        
    private func prepareView() {
        backgroundColor = .white
        addSubview(datelineView)
        addSubview(calendarBtn)
        addSubview(timeCollView)
        addSubview(loadingAnim)
        addSubview(selectView)
        addSubview(indicatorLine)
    }
    
    private func prepareEvent() {
        
        calendarBtn.addEvent { [unowned self](_) in
            let superview = self.nextViewController?.view
            superview?.addSubview(self.calendarView)
            self.calendarView.snp.makeConstraints { (make) in
                make.height.equalTo(400)
                make.width.equalTo(375)
                make.centerX.equalToSuperview()
                make.bottom.equalTo(superview!.snp.bottomMargin)
            }
            
            if self.calendarView.alpha < 0.01 {
                self.calendarView.alpha = 0
                self.calendarView.transform = CGAffineTransform(translationX: 0, y: 400)
                UIView.animate(withDuration: 0.3, animations: {
                    self.calendarView.alpha = 1
                    self.calendarView.transform = .identity
                })
                self.calendarView.currentDate = self.viewModel.current.date
            }
        }

        selectView.didChangeValue = { [unowned self] (leftView, rightView)in
            let leftDiff  = indicatorLine.frame.midX - leftView.frame.maxX
            let rightDiff = indicatorLine.frame.midX - rightView.frame.minX

            let startTime = viewModel.renderSections.first!.items.first!.start
            let endTime   = viewModel.renderSections.last!.items.last!.end

            var leftTime  = Double(self.timeCollView.contentOffset.x - leftDiff)  / self.viewModel.scale + startTime
            var rightTime = Double(self.timeCollView.contentOffset.x - rightDiff) / self.viewModel.scale + startTime

            leftTime = min(max(leftTime, startTime), endTime)
            rightTime = min(max(rightTime, startTime), endTime)

            let longest = rightTime - leftTime >= 10 * 60 // 10分钟
            self.selectView.longTimeEnable = !longest
            self.delegate?.timelineView(self, didSelectRangeAt: IVTime(start: leftTime, end: rightTime), longest: longest)
        }
        
        viewModel.state.observe { [weak self](state, _) in
            guard let `self` = self else { return }
            logInfo("IotVideoDemo.IVTimelineState",state)

            if state == .selecting {
                if self.viewModel.update(scale: 0.4) { //固定一个比例选择片段
                    self.timeCollView.reloadData()
                    self.scrollToTime(self.viewModel.pts.value, animated: false)
                }
            }
            self.selectView.isHidden = (state != .selecting) // 显示的时候会触发一次回调
        }
        
        viewModel.pts.observe { [weak self](pts, old) in
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                if self.viewModel.state.value == .tracking {
                    let sectionTime = self.viewModel.current.time
                    if pts < sectionTime.start {
                        self.loadAndDisplaySection(at: sectionTime.before(days: UInt(sectionTime.start - pts) / 86400 + 1), scrollToTime: pts)
                    } else if pts > sectionTime.end {
                        self.loadAndDisplaySection(at: sectionTime.after(days: UInt(pts - sectionTime.end) / 86400 + 1), scrollToTime: pts)
                    } else {
                        self.scrollToTime(pts, animated: true)
                    }
                }
            }
        }
        
        datelineView.selectedDateCallback = { [weak self] date in
            self?.loadAndDisplaySection(at: IVTime(date: date))
        }
        
        calendarView.selectedDateCallback = { [weak self] date in
            self?.calendarView.alpha = 0
            self?.loadAndDisplaySection(at: IVTime(date: date))
        }

        calendarView.markableDatesDataSource = { [weak self] (t0, t1, callback) in
            guard let `self` = self else { return }
            self.delegate?.timelineView(self, markListForCalendarAt: IVTime(start: t0, end: t1), completionHandler: { (markList) in
                let dates = markList?.map { TimeInterval($0) } ?? []
                callback(dates)
            })
        }
    }
    
    private func prepareLayout() {
        calendarBtn.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(3)
            make.right.equalToSuperview()
            make.width.height.equalTo(38)
        }

        datelineView.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview()
            make.height.equalTo(46)
            make.right.equalToSuperview()
        }

        timeCollView.snp.makeConstraints { (make) in
            make.top.equalTo(datelineView.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        indicatorLine.snp.makeConstraints { (make) in
            make.bottom.centerX.equalTo(timeCollView)
            make.width.equalTo(8)
            make.top.equalTo(timeCollView).offset(-6)
        }
        
        loadingAnim.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
        selectView.snp.makeConstraints { (make) in
            make.edges.equalTo(timeCollView)
        }
    }
    
    
    private func updateLayout() {
        timeCollView.snp.remakeConstraints { (make) in
            if gIsLandscape {
                make.top.equalToSuperview()
            } else {
                make.top.equalTo(datelineView.snp.bottom)
            }
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    /// 预加载数据
    func preloadSectionIfNeed(at time: IVTime, isBackward : Bool, scrollToTime: TimeInterval? = nil) {
        DispatchQueue.main.async {[weak self] in
            guard let `self` = self else { return }
                        
            if !self.viewModel.sections.contains(where: { time == $0.time }),
                !self.loadingTimes.contains(time) {
                self.loadingTimes.append(time)
                self.loadingAnim.startAnimating()

                self.delegate?.timelineView(self, itemsForTimelineAt: time) {(items) in
                    DispatchQueue.main.async {[weak self] in
                        guard let `self` = self else { return }
                        self.loadingTimes.removeAll(where: { $0 == time})
                        self.loadingAnim.stopAnimating()
                        if let items = items {
                            logInfo("下载成功 \(time.dateString) 个数：\(items.count)")
                            
                            self.viewModel.insertSection(items: items, for: time)
                            
                            self.timeCollView.reloadData()
                            if self.viewModel.current.time == time {
                                if let destItem = isBackward ? self.viewModel.current.items.last(where: { $0.isValid }) : self.viewModel.current.items.first(where: { $0.isValid }) {
                                    self.scrollToTime(destItem.start, animated: true)
                                } else if let scrollToTime = scrollToTime {
                                    self.scrollToTime(scrollToTime, animated: true)
                                }
                            }
                        } else {
                            logError("下载失败 \(time.dateString)")
                        }
                    }
                }
            }
        }
    }
    
    /// 加载并刷新UI
    func loadAndDisplaySection(at time: IVTime, scrollToTime: TimeInterval? = nil, complete:(()->Void)? = nil) {
        DispatchQueue.main.async {[weak self] in
            guard let `self` = self else { return }
            let isSameTime = (self.viewModel.current.time == time)
            let timeOffset = Int(time.start) - Int(self.viewModel.current.start)

            // 通知外部点击的日期
            self.delegate?.timelineView(self, didSelectDateAt: time)

            if !isSameTime || self.viewModel.current.isPlaceholder {
                self.viewModel.loadSection(for: time)
                self.datelineView.selectedDate = time.date

                for section in self.viewModel.renderSections where section.isPlaceholder {
                    self.preloadSectionIfNeed(at: section.time, isBackward: timeOffset < 0, scrollToTime: scrollToTime)
                }
                if self.viewModel.current.isPlaceholder, isSameTime {
                    complete?()
                    return // 相同日期
                }
                                
                self.timeCollView.reloadData()
                
                if let scrollToTime = scrollToTime {
                    self.scrollToTime(scrollToTime, animated: false)
                } else if !self.viewModel.current.isPlaceholder,
                    let destItem = timeOffset < 0 ? self.viewModel.current.items.last(where: { $0.isValid }) : self.viewModel.current.items.first(where: { $0.isValid }) {
                    self.scrollToTime(destItem.start, animated: true)
                } else {
                    self.scrollToTime(time.start + 5, animated: true)

                    self.timeCollView.transform = CGAffineTransform(translationX: timeOffset < 0 ? -100 : 100, y: 0)
                    UIView.animate(withDuration: 0.2) {
                        self.timeCollView.transform = .identity
                    }
                }
            }
            complete?()
        }
    }
    
    var isTimeCollViewInteracting: Bool {
        return timeCollView.isDragging ||
            timeCollView.isTracking ||
            timeCollView.isDecelerating
    }
        
    func scrollToTime(_ time: TimeInterval, animated: Bool) {
        let startTime = viewModel.renderSections.first!.items.first!.start
        let endTime   = viewModel.renderSections.last!.items.last!.end
        let time = min(max(time, startTime), endTime)
        let offsetX = CGFloat(time - startTime) * CGFloat(viewModel.scale)
        let point = CGPoint(x: offsetX, y: timeCollView.contentOffset.y)
        self.timeCollView.setContentOffset(point, animated: animated)
        if Int(viewModel.pts.value) != Int(time) {
            viewModel.pts.value = time
        }
    }
    
    @objc func pinchGestureHandler(_ pinch: UIPinchGestureRecognizer) {

        switch pinch.state {
        case .began:
            viewModel.state.value = .zooming
        case .changed:
            let oldScale = viewModel.scale
            if viewModel.update(scale: oldScale * Double(pinch.scale)) {
//                CATransaction.setDisableActions(true)
                timeCollView.reloadData()
                scrollToTime(viewModel.pts.value, animated: false)
//                CATransaction.commit()
            }
        default:
            IVDelayWork.asyncAfter(1, key: "isManuallyScroll-did-end") {[weak self] in
                if self?.viewModel.state.value == .zooming {
                    logInfo("IotVideoDemo.IVTimelineState zoom end")
                    self?.viewModel.state.value = .tracking
                }
            }
        }
        pinch.scale = 1
    }
    
    private func scrollhandler(didEnd: Bool) {
        guard viewModel.state.value != .tracking, !viewModel.current.items.isEmpty else {
            return
        }
                
        for cell in timeCollView.visibleCells {
            guard let cell = cell as? IVTimelineCell else {
                continue
            }
            let cellRect = timeCollView.convert(cell.frame, to: self)
            let indRect = indicatorLine.frame
            
            guard cellRect.minX - 0.5 <= indRect.midX && indRect.midX <= cellRect.maxX + 0.5 else {
                continue
            }
            
            let startTime = viewModel.renderSections.first!.items.first!.start
            let endTime   = viewModel.renderSections.last!.items.last!.end

            var seekTime = Double(timeCollView.contentOffset.x) / self.viewModel.scale + startTime
            seekTime = min(max(seekTime, startTime), endTime)
             
            viewModel.pts.value = seekTime
            delegate?.timelineView(self, didScrollTo: seekTime)

            if didEnd {
                if seekTime < self.datelineView.selectedDate.timeIntervalSince1970 {
                    let prevSection = self.viewModel.renderSections[0]
                    self.loadAndDisplaySection(at: prevSection.time, scrollToTime: seekTime) {
                        self.autoScrollToValidItem(seekTime)
                    }
                    return
                } else if seekTime > self.datelineView.selectedDate.timeIntervalSince1970 + 86400 {
                    if self.viewModel.current.time < .today {
                        let nextSection = self.viewModel.renderSections[2]
                        self.loadAndDisplaySection(at: nextSection.time, scrollToTime: seekTime) {
                            self.autoScrollToValidItem(seekTime)
                        }
                        return
                    }
                }
                
                autoScrollToValidItem(seekTime)
            } else {
                IVDelayWork.cancelTask(withKey: "selected next-item")
            }
            break
        }
        
        IVDelayWork.asyncAfter(1, key: "isManuallyScroll-did-end") {[weak self] in
            guard let `self` = self else { return }
            if !self.isTimeCollViewInteracting && self.viewModel.state.value == .dragging {
                logInfo("IotVideoDemo.IVTimelineState.dragging end")
                self.viewModel.state.value = .tracking
            }
        }
    }
    
    func autoScrollToValidItem(_ seekTime: Double) {
        if let item = viewModel.currentRawItem {
            logDebug("selected curr_item \(String(describing: item)) at \(seekTime)")
            delegate?.timelineView(self, didSelectItem: item, at: seekTime)
        } else if let item = viewModel.nextRawItem, item.start < viewModel.current.end {
            let origOffX = timeCollView.contentOffset.x
            IVDelayWork.asyncAfter(1, key: "selected next_item") {[weak self] in
                guard let `self` = self else { return }
                if Int(origOffX) == Int(self.timeCollView.contentOffset.x) {
                    logDebug("selected next_item \(String(describing: item)) at \(seekTime)")
                    self.scrollToTime(item.start, animated: true)
                    self.delegate?.timelineView(self, didSelectItem: item, at: item.start)
                }
            }
        }
    }
    
}

// MARK: - 数据源

extension IVTimelineView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if viewModel.current.time == .today {
            return viewModel.renderSections.count - 1
        } else {
            return viewModel.renderSections.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.renderSections[section].items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IVTimelineCell", for: indexPath) as! IVTimelineCell
        let item = viewModel.renderSections[indexPath.section].items[indexPath.item]
        let time = IVTime(start: item.start, end: item.end)
        cell.update(time: time, color: item.color, isValid: item.isValid, scale: viewModel.scale)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerfooter = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath) as! IVTimelineHeaderFooter
        headerfooter.setNeedsDisplay()
        if kind == UICollectionView.elementKindSectionFooter,
           viewModel.current.time == .today {
            headerfooter.loadingAnim.stopAnimating()
        } else {
            headerfooter.loadingAnim.startAnimating()
        }

        return headerfooter
    }
}

// MARK: - 布局

extension IVTimelineView: UICollectionViewDelegateFlowLayout {
        
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = viewModel.renderSections[indexPath.section].items[indexPath.item]
        if !item.isValid { return }
        scrollToTime(item.start, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = viewModel.renderSections[indexPath.section].items[indexPath.item]
        let fscale = Double(UIScreen.main.scale) * viewModel.scale
        let floorStart = floor(fscale * item.start) / Double(UIScreen.main.scale)
        let floorEnd = floor(fscale * item.end) / Double(UIScreen.main.scale)
        let newItemW = CGFloat(floorEnd - floorStart)
        return CGSize(width: newItemW, height: collectionView.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
        
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let W = (section == 0 ? collectionView.bounds.width/2 : 0)
        return CGSize(width: W, height: collectionView.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let W = (section == collectionView.numberOfSections - 1  ? collectionView.bounds.width/2 : 0)
        return CGSize(width: W, height: collectionView.bounds.height)
    }
    
    // MARK: - 代理
        
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        viewModel.state.value = .dragging
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.isDecelerating { return }
        
        if decelerate { return }
        scrollhandler(didEnd: true)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollhandler(didEnd: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollhandler(didEnd: false)
    }
}


// MARK: - Cell视图

fileprivate class IVTimelineCell: UICollectionViewCell {
    
    private(set) var time: IVTime = .today
    private(set) var color: UIColor = .white
    private(set) var isValid: Bool = false
    private(set) var scale = 1.0
        
    func update(time: IVTime, color: UIColor, isValid: Bool, scale: Double) {
        self.time = time
        self.color = color
        self.isValid = isValid
        self.scale  = scale
        timeMarks = IVTimeMark.all.filter { scale * Double($0.rawValue) >= 4.8 } // 距离大于 4.8 pt
        setNeedsDisplay()
    }
            
    /// === 时间刻度 ===
    private var timeMarks: [IVTimeMark] = [.hour]
           
    private func TimeOffset(of mark: IVTimeMark) -> TimeInterval {
        let remain: TimeInterval = time.start - floor(time.start) // 小数点后的余数
        let mod: TimeInterval = TimeInterval(Int(time.start) % mark.rawValue) + remain // 小数点前整数
        let offset: TimeInterval = mod > 0.001 ? TimeInterval(mark.rawValue) - mod : 0
        return offset
    }
    
    private lazy var dateFormater = IVTimeMark.all.reduce(into: [IVTimeMark : DateFormatter]()) { (dict, mark) in
        let fmt = DateFormatter()
        fmt.dateFormat = DateFormat(of: mark)
        dict[mark] = fmt
    }
    
    private func DateFormat(of mark: IVTimeMark) -> String {
        return mark < .min1 ? "ss" : "HH:mm"
    }
        
    private func StrokeColor(of mark: IVTimeMark) -> UIColor {
        let alpha = ((CGFloat(mark.rawValue) * CGFloat(scale) - 2) / 200) + 0.2
        let color = UIColor(white: 0, alpha: alpha)
        return color
    }
        
    // === 刻度\文字 ===
    private func drawTimelineMark(_ ctx: CGContext?) {
        let miniMark = timeMarks.last!
        let miniStep = CGFloat(miniMark.rawValue) * CGFloat(scale)
        var offset   = TimeOffset(of: miniMark)
        let offsetW  = CGFloat(offset * scale)
        let halfLabelW = LabelWidth(of: timeMarks.first!) / 2
        let halfLabelT = Double(halfLabelW) / scale
        let multiple = ceil((offsetW + halfLabelW) / miniStep)
        offset  = offset - Double(multiple * miniStep) / scale
             
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        
        let maxMarkHeight = MarkHeight(of: .hour4)

        while offset <= time.duration + halfLabelT {
            let offX = CGFloat(scale * offset) // min(max(CGFloat(scale * offset), self.bounds.minX - miniStep), self.bounds.maxX + miniStep)

            for mark in timeMarks {
//                print("markline \(time) \(miniMark.rawValue)    \(mark.rawValue)    \(offset)   \(time.start + offset)")
                if (Int(time.start + offset) % mark.rawValue == 0) {
//                    print("markline -")

                    // 刻度/文字颜色
//                    let color = StrokeColor(of: mark)
                    let color = UIColor(hexString: "#9DA5AD")
                    
                    // === 1.画刻度 ===
                    let markHeight = MarkHeight(of: mark)
                    ctx?.setLineWidth(1)
                    ctx?.setStrokeColor(color.cgColor)
                    ctx?.move(to:    CGPoint(x: offX, y: bounds.height - verticalInset))
                    ctx?.addLine(to: CGPoint(x: offX, y: bounds.height - verticalInset - CGFloat(markHeight)))
                    ctx?.strokePath()

                    // === 2.画文字 ===
                    let fontSize = FontSize(of: mark)

                    let fmt = dateFormater[mark]!
 
                    let labelWidth = LabelWidth(of: mark)
                    let showText = CGFloat(mark.rawValue) * CGFloat(scale) > labelWidth

                    if showText, mark >= .sec10 {
                        for divisor in IVTimeMark.divisors {
                            if Int(round(time.start + Double(offX))) % divisor == 0 {
                                let font = UIFont.systemFont(ofSize: fontSize)
                                let string = NSAttributedString(string: fmt.string(from: Date(timeIntervalSince1970: time.start + offset)),
                                                                attributes: [.font : font,
                                                                             .foregroundColor : color,
                                                                             .paragraphStyle : style])
                                string.draw(in: CGRect(x: offX-labelWidth/2,
                                                       y: bounds.height-verticalInset-CGFloat(maxMarkHeight)-20,
                                                       width: labelWidth,
                                                       height: 20))
                                break
                            }
                        }
                    }
                
                    // === 3.该时间点绘制完毕 ===
                    break
                }
            }
            offset += Double(miniMark.rawValue)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
//        print(self.classForCoder, "alloc")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        // 颜色块
        ctx?.setFillColor(color.cgColor)
        ctx?.fill(rect.insetBy(dx: 0, dy: verticalInset))
        // 刻度
        drawTimelineMark(ctx)
    }
}

// MARK: - 头尾视图

fileprivate class IVTimelineHeaderFooter: UICollectionReusableView {
    
    lazy var btn: UIButton = {
        let btn = UIButton(frame: bounds)
        btn.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        btn.setTitleColor(.blue, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15)
        return btn
    }()
    
    lazy var loadingAnim = UIActivityIndicatorView(style: .gray).then {
        $0.startAnimating()
        $0.frame = self.bounds
        $0.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleBottomMargin, .flexibleRightMargin]
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(btn)
        addSubview(loadingAnim)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        // 背景色
        ctx?.setFillColor(UIColor(white: 0.98, alpha: 1).cgColor)
        ctx?.fill(rect)
        // 绘制00:00
        let color = UIColor(hexString: "#9DA5AD")
        let mark = IVTimeMark.hour4
        let markHeight = MarkHeight(of: mark)
        let font = UIFont.systemFont(ofSize: FontSize(of: mark))
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let string = NSAttributedString(string: "00:00",
                                        attributes: [.font : font,
                                                     .foregroundColor : color,
                                                     .paragraphStyle : style])
        let isHeader = (reuseIdentifier == UICollectionView.elementKindSectionHeader)
        let labelWidth = LabelWidth(of: mark)
        let offX = isHeader ? bounds.width : 0
        string.draw(in: CGRect(x: offX-labelWidth/2,
                               y: bounds.height-CGFloat(markHeight)-verticalInset-20,
                               width: labelWidth,
                               height: 20))
        // 绘制｜
        ctx?.setLineWidth(2)
        ctx?.setStrokeColor(color.cgColor)
        ctx?.move(to: CGPoint(x: offX, y: bounds.height-verticalInset))
        ctx?.addLine(to: CGPoint(x: offX, y: bounds.height-CGFloat(markHeight)-verticalInset))
        ctx?.strokePath()
    }
}

private let verticalInset: CGFloat = 0

private func FontSize(of mark: IVTimeMark) -> CGFloat {
    if mark.rawValue >= IVTimeMark.min1.rawValue  {
        return 14
    }
    return 10
}

private func DateFormat(of mark: IVTimeMark) -> String {
    return mark < .min1 ? "ss" : "HH:mm"
}

private var _widthCaches: [IVTimeMark : CGFloat] = [:]
private func LabelWidth(of mark: IVTimeMark) -> CGFloat {
    if let width = _widthCaches[mark] {
        return width
    }
    let text = DateFormat(of: mark) as NSString
    let width = max(44, text.boundingRect(with: CGSize(width: 100, height: 14),
                                  options: .usesFontLeading,
                                  attributes: [.font : UIFont.systemFont(ofSize: FontSize(of: mark))],
                                  context: nil).width)
    _widthCaches[mark] = width
    return width
}

private func MarkHeight(of mark: IVTimeMark) -> Double {
    switch mark {
    case .hour4, .hour2, .hour: return 20
    case .min30: return 20
    case .min10: return 10
    case .min5, .min1: return 10
    case .sec30: return 5
    case .sec10: return 5
    case .sec5, .sec1: return 5
    }
}

// MARK: - 选择视图

fileprivate class IVTimelineSelectView: UIView {
    
    /// 是否还能放大时间
    var longTimeEnable: Bool = true
    let selectIndLeft = UIImageView().then {
        $0.contentMode = .right
        $0.image = UIImage(named: "iot_select_indicator_left")
    }

    let selectIndRight = UIImageView().then {
        $0.contentMode = .left
        $0.image = UIImage(named: "iot_select_indicator_right")
    }
    
    let selectIndicator = UIImageView().then {
        $0.contentMode = .center
        $0.image = UIImage(named: "iot_select_indicator")
    }
    
    var didChangeValue: ((_ leftView: UIView, _ rightView: UIView) -> Void)?
    
    override var isHidden: Bool {
        didSet {
            if !isHidden { didChangeValue?(selectIndLeft, selectIndRight) }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        
        addSubview(selectIndLeft)
        addSubview(selectIndRight)
        addSubview(selectIndicator)
        
        selectIndLeft.addPanGesture { [unowned self](pan) in
            if let pan = pan as? UIPanGestureRecognizer, let panView = pan.view {
                let changeX = pan.translation(in: self).x
                if !self.longTimeEnable, changeX < 0 {
                    return
                }
                panView.frame.origin.x += changeX
                if panView.frame.origin.x < 0 {
                    panView.frame.origin.x = 0
                } else if panView.frame.maxX > self.selectIndRight.frame.minX {
                    panView.frame.origin.x = self.selectIndRight.frame.minX - 20
                }
                self.selectIndicator.frame.origin.x = panView.frame.origin.x + 20 - 4.5//(ui切图修正)
                self.setNeedsDisplay()
                pan.setTranslation(.zero, in: self)
                self.didChangeValue?(self.selectIndLeft, self.selectIndRight)
            }
        }

        selectIndRight.addPanGesture { [unowned self](pan) in
            if let pan = pan as? UIPanGestureRecognizer, let panView = pan.view {
                
                let changeX = pan.translation(in: self).x
                if !self.longTimeEnable, changeX > 0 {
                    return
                }
                panView.frame.origin.x += changeX
                if panView.frame.origin.x < self.selectIndLeft.frame.maxX {
                    panView.frame.origin.x = self.selectIndLeft.frame.maxX
                } else if panView.frame.origin.x > self.bounds.width - 20 {
                    panView.frame.origin.x = self.bounds.width - 20
                }
                self.selectIndicator.frame.origin.x = panView.frame.origin.x - 12 + 4.3//(ui切图修正)
                self.setNeedsDisplay()
                pan.setTranslation(.zero, in: self)
                self.didChangeValue?(self.selectIndLeft, self.selectIndRight)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
            
    override func layoutSubviews() {
        super.layoutSubviews()
        selectIndLeft.frame  = CGRect(x: bounds.width/2 - 20, y: verticalInset, width: 20, height: bounds.height - 2 * verticalInset)
        selectIndicator.frame = CGRect(x: selectIndLeft.frame.origin.x + 20 - 4.5, y: verticalInset - 5.5, width: 12, height: 73)
        selectIndRight.frame = CGRect(x: bounds.width/2 + 20, y: verticalInset, width: 20, height: bounds.height - 2 * verticalInset)
    }
        
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.clear(bounds)
        
        // 选中区域
        let selectRect = CGRect(x: selectIndLeft.frame.midX,
                           y: verticalInset,
                           width: selectIndRight.frame.midX - selectIndLeft.frame.midX,
                           height: bounds.height - 2 * verticalInset)

        // 选中区域边框
        ctx?.setLineJoin(.round)
        ctx?.setLineWidth(3)
        ctx?.setStrokeColor(UIColor.white.cgColor)
        ctx?.stroke(selectRect)
        
        // 半透明蒙层
        ctx?.addPath(UIBezierPath(rect: bounds).cgPath)
        ctx?.addPath(UIBezierPath(rect: selectRect).cgPath)
        ctx?.setFillColor(UIColor.init(white: 0, alpha: 0.5).cgColor)
        ctx?.fillPath(using: .evenOdd)
    }
}

// MARK: - 指示线

fileprivate class IVIndicatorLine: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {return}
        context.beginPath()
        context.move(to: CGPoint(x: 0, y: 0))
        context.addLine(to: CGPoint(x: rect.width, y: 0))
        context.addLine(to: CGPoint(x: (rect.maxX / 2.0), y: 5))
        context.closePath()
        context.setFillColor(UIColor(hexString: "#2976FF").cgColor)
        context.fillPath()
        context.move(to: CGPoint(x: (rect.maxX / 2.0), y: 4))
        context.addLine(to: CGPoint(x: rect.maxX / 2.0, y: rect.maxY))
        context.setStrokeColor(UIColor(hexString: "#2976FF").cgColor)
        context.strokePath()
    }
}

