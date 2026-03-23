// PicSwipe/Views/Filter/FilterView.swift
import SwiftUI

/// 筛选清理页 — 卡片分组式布局
/// 快捷筛选（截图/大文件）+ 时间范围 + 相册选择
struct FilterView: View {
    @Binding var path: NavigationPath
    @Binding var cleanSession: CleanSession?
    let mode: CleanMode

    @Environment(PhotoLibraryService.self) private var photoService

    @State private var vm = FilterViewModel()
    @State private var showDatePicker = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: Spacing.sm) {
                        quickFilterCard
                        timeRangeCard
                        albumCard
                    }
                    .padding(.horizontal, Spacing.pagePadding)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, 140) // 给底部按钮留空间
                }

                stickyBottom
            }
        }
        .navigationTitle("筛选清理")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    path.removeLast()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("重置") {
                    vm.resetAll()
                    vm.updateMatchingCount(photoService: photoService)
                }
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.startLocation.x < 60 && value.translation.width > 80 {
                        path.removeLast()
                    }
                }
        )
        .task {
            vm.mode = mode
            await vm.loadAlbums(photoService: photoService)
            vm.updateMatchingCount(photoService: photoService)
        }
    }

    // MARK: - 快捷筛选卡片

    private var quickFilterCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 0) {
                Text("📷 快捷筛选")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.bottom, Spacing.sm)

                // 仅截图
                filterToggleRow(
                    title: "仅截图",
                    subtitle: "筛选所有屏幕截图",
                    isOn: vm.screenshotsOnly,
                    enabled: mode == .photo
                ) {
                    vm.toggleScreenshots()
                    vm.updateMatchingCount(photoService: photoService)
                }

                Divider().background(Color.white.opacity(0.06))

                // 大文件优先
                filterToggleRow(
                    title: "大文件优先",
                    subtitle: "优先展示 >10MB 的文件",
                    isOn: vm.largeFilesOnly
                ) {
                    vm.toggleLargeFiles()
                    vm.updateMatchingCount(photoService: photoService)
                }
            }
        }
    }

    private func filterToggleRow(
        title: String,
        subtitle: String,
        isOn: Bool,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(enabled ? .white : Color.textMuted)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            // 自定义 Toggle 外观
            Button {
                guard enabled else { return }
                action()
            } label: {
                RoundedRectangle(cornerRadius: 14)
                    .fill(isOn ? Color.brandPrimary : Color.textMuted)
                    .frame(width: 46, height: 28)
                    .overlay(
                        Circle()
                            .fill(.white)
                            .frame(width: 22, height: 22)
                            .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
                            .offset(x: isOn ? 9 : -9),
                        alignment: .center
                    )
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isOn)
            }
            .opacity(enabled ? 1 : 0.4)
        }
        .padding(.vertical, 10)
    }

    // MARK: - 时间范围卡片

    private var timeRangeCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("📅 时间范围")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                // 预设按钮
                let presets: [TimePreset] = [.all, .oneYear, .twoYears, .threeYears, .custom]
                FlowLayout(spacing: 8) {
                    ForEach(presets, id: \.self) { preset in
                        Button {
                            vm.selectTimePreset(preset)
                            if preset == .custom {
                                showDatePicker = true
                            } else {
                                showDatePicker = false
                            }
                            vm.updateMatchingCount(photoService: photoService)
                        } label: {
                            Text(preset.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(
                                    vm.selectedTimePreset == preset ? Color.brandPrimary : Color.textSecondary
                                )
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    vm.selectedTimePreset == preset
                                        ? Color.brandPrimary.opacity(0.15)
                                        : Color.white.opacity(0.06)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            vm.selectedTimePreset == preset ? Color.brandPrimary : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                        }
                    }
                }

                // 自定义日期选择器
                if showDatePicker {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("清理此日期之前的内容")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                        DatePicker(
                            "",
                            selection: $vm.customStartDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .colorScheme(.dark)
                        .onChange(of: vm.customStartDate) { _, _ in
                            vm.updateMatchingCount(photoService: photoService)
                        }
                    }
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showDatePicker)
    }

    // MARK: - 相册选择卡片

    private var albumCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("📁 相册选择")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Spacer()

                    if !vm.selectedAlbumIds.isEmpty {
                        Text("已选 \(vm.selectedAlbumIds.count)")
                            .font(.caption)
                            .foregroundStyle(Color.brandPrimary)
                    }
                }

                if vm.isLoadingAlbums {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(Color.brandPrimary)
                        Spacer()
                    }
                    .padding(.vertical, Spacing.md)
                } else if vm.albums.isEmpty {
                    Text("没有找到相册")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .padding(.vertical, Spacing.md)
                } else {
                    ForEach(Array(vm.albums.enumerated()), id: \.element.id) { index, album in
                        if index > 0 {
                            Divider().background(Color.white.opacity(0.06))
                        }
                        albumRow(album: album)
                    }
                }
            }
        }
    }

    private func albumRow(album: AlbumInfo) -> some View {
        let isSelected = vm.selectedAlbumIds.contains(album.id)
        return Button {
            vm.toggleAlbum(id: album.id)
            vm.updateMatchingCount(photoService: photoService)
        } label: {
            HStack(spacing: Spacing.md) {
                // 勾选框
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.brandPrimary : Color.clear)
                    .frame(width: 22, height: 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? Color.brandPrimary : Color.textMuted, lineWidth: 1.5)
                    )
                    .overlay(
                        isSelected
                            ? Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.black)
                            : nil
                    )
                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)

                // 相册名
                Text(album.title)
                    .font(.body)
                    .foregroundStyle(.white)

                Spacer()

                // 数量
                Text("\(album.count)")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
    }

    // MARK: - 底部固定栏

    private var stickyBottom: some View {
        VStack(spacing: 10) {
            // 匹配数量
            HStack(spacing: 4) {
                Text("符合条件")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                if vm.isLoadingCount {
                    ProgressView()
                        .tint(Color.brandPrimary)
                        .scaleEffect(0.7)
                } else {
                    Text("\(vm.matchingCount)")
                        .font(.pixel(10))
                        .foregroundStyle(Color.brandPrimary)
                }
                Text(mode == .photo ? "张照片" : "个视频")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }

            // 开始清理按钮
            PrimaryButton(title: "开始清理") {
                let filter = vm.buildFilter()
                path.append(AppDestination.swipeWithFilter(mode, filter))
            }
            .opacity(vm.matchingCount > 0 ? 1 : 0.5)
            .disabled(vm.matchingCount == 0)
        }
        .padding(.horizontal, Spacing.pagePadding)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.xl)
        .background(
            LinearGradient(
                colors: [Color.appBackground.opacity(0), Color.appBackground],
                startPoint: .top,
                endPoint: .init(x: 0.5, y: 0.3)
            )
        )
    }
}

// MARK: - FlowLayout（自动换行布局）

/// 简易 FlowLayout，用于时间预设按钮自动换行
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxHeight = max(maxHeight, y + rowHeight)
        }

        return (CGSize(width: maxWidth, height: maxHeight), positions)
    }
}
