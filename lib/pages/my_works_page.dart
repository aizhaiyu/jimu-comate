import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/providers/project_provider.dart';
import 'package:app/models/project_models.dart';
import 'package:app/pages/lego_studio_page.dart';
import 'package:intl/intl.dart';

class MyWorksPage extends ConsumerStatefulWidget {
  const MyWorksPage({super.key});

  @override
  ConsumerState<MyWorksPage> createState() => _MyWorksPageState();
}

class _MyWorksPageState extends ConsumerState<MyWorksPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectProvider);
    final filteredProjects = ref.watch(filteredProjectsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    // 调试信息
    debugPrint('MyWorksPage build - projects count: ${projectState.projects.length}');
    debugPrint('MyWorksPage build - filteredProjects count: ${filteredProjects.length}');
    debugPrint('MyWorksPage build - isLoading: ${projectState.isLoading}');
    debugPrint('MyWorksPage build - error: ${projectState.error}');
    debugPrint('MyWorksPage build - isLandscape: $isLandscape');

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF111827),
              Color(0xFF1F2937),
              Color(0xFF111827),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: isLandscape
                ? _buildLandscapeLayout(projectState, filteredProjects, screenWidth, screenHeight)
                : _buildPortraitLayout(projectState, filteredProjects, screenWidth, screenHeight),
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(ProjectState projectState, List<ProjectData> projects, double screenWidth, double screenHeight) {
    return Row(
      children: [
        // 左侧边栏区域 - 固定宽度
        Container(
          width: 320,
          padding: const EdgeInsets.all(16), // 减小内边距
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCompactHeader(projectState),
                const SizedBox(height: 16), // 减小间距
                _buildSearchBar(),
                const SizedBox(height: 16), // 减小间距
                _buildCompactActionButtons(projectState, projects),
                if (projectState.error != null) ...[
                  const SizedBox(height: 8), // 减小间距
                  _buildErrorMessage(projectState.error!),
                ],
                // 添加底部安全区域
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        
        // 分隔线
        Container(
          width: 1,
          height: double.infinity,
          color: Colors.white.withOpacity(0.1),
        ),
        
        // 右侧内容区域 - 自适应宽度
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 顶部统计信息
                _buildStatsBar(projects),
                const SizedBox(height: 20),
                
                // 项目网格
                Expanded(
                  child: projectState.isLoading
                      ? _buildLoadingState()
                      : projects.isEmpty
                          ? _buildLandscapeEmptyState()
                          : _buildOptimizedLandscapeGrid(projects),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(ProjectState projectState, List<ProjectData> projects, double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.02,
      ),
      child: Column(
        children: [
          _buildHeader(projectState),
          const SizedBox(height: 16),
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildActionButtons(projectState, projects),
          const SizedBox(height: 16),
          if (projectState.error != null)
            _buildErrorMessage(projectState.error!),
          Expanded(
            child: projectState.isLoading
                ? _buildLoadingState()
                : projects.isEmpty
                    ? _buildEmptyState()
                    : _buildPortraitGrid(projects),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ProjectState projectState) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            '我的作品',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
        _buildSortButton(),
        const SizedBox(width: 12),
        _buildViewModeButton(),
      ],
    );
  }

  Widget _buildCompactHeader(ProjectState projectState) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '我的作品',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${projectState.projects.length} 个项目',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsBar(List<ProjectData> projects) {
    final totalBricks = projects.fold<int>(0, (sum, project) => sum + project.brickCount);
    final recentProjects = projects.where((p) => 
      p.updatedAt.isAfter(DateTime.now().subtract(const Duration(days: 7)))
    ).length;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.collections_bookmark,
              title: '总项目',
              value: '${projects.length}',
              color: const Color(0xFF3B82F6),
            ),
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.white.withOpacity(0.1),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.view_in_ar,
              title: '总积木',
              value: '$totalBricks',
              color: const Color(0xFF10B981),
            ),
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.white.withOpacity(0.1),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.access_time,
              title: '最近更新',
              value: '$recentProjects',
              color: const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionButtons(ProjectState projectState, List<ProjectData> projects) {
    return Column(
      mainAxisSize: MainAxisSize.min, // 避免Column占用过多空间
      children: [
        SizedBox(
          width: double.infinity,
          height: 40, // 减小高度
          child: _buildActionButton(
            icon: Icons.add,
            title: '新建项目',
            color: const Color(0xFF10B981),
            onTap: () => _createNewProject(),
          ),
        ),
        const SizedBox(height: 10), // 减小间距
        SizedBox(
          width: double.infinity,
          height: 40, // 减小高度
          child: _buildActionButton(
            icon: Icons.file_upload,
            title: '导入项目',
            color: const Color(0xFF3B82F6),
            onTap: () => _importProject(),
            isLoading: projectState.isImporting,
          ),
        ),
        if (projects.isNotEmpty) ...[
          const SizedBox(height: 10), // 减小间距
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.refresh,
                  title: '刷新',
                  color: const Color(0xFF8B5CF6),
                  isSmall: true,
                  onTap: () => ref.read(projectNotifierProvider).refreshProjects(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactSortButton(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCompactSortButton() {
    final sortMode = ref.watch(projectProvider).sortMode;
    
    return Container(
      height: 40, // 减小高度与其他按钮一致
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showSortOptions(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sort,
                color: Colors.white,
                size: 14, // 减小图标
              ),
              const SizedBox(width: 4), // 减小间距
              Expanded(
                child: Text(
                  _getSortModeText(sortMode),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11, // 减小字体
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    final sortMode = ref.watch(projectProvider).sortMode;
    
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showSortOptions(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sort,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _getSortModeText(sortMode),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeButton() {
    final viewMode = ref.watch(projectProvider).viewMode;
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            ref.read(projectNotifierProvider).setViewMode(
              viewMode == ProjectViewMode.grid
                  ? ProjectViewMode.list
                  : ProjectViewMode.grid,
            );
          },
          child: Icon(
            viewMode == ProjectViewMode.grid ? Icons.view_list : Icons.grid_view,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: const InputDecoration(
          hintText: '搜索项目名称或标签...',
          hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
          prefixIcon: Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
        },
      ),
    );
  }

  Widget _buildActionButtons(ProjectState projectState, List<ProjectData> projects) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.add,
            title: '新建项目',
            color: const Color(0xFF10B981),
            onTap: () => _createNewProject(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.file_upload,
            title: '导入项目',
            color: const Color(0xFF3B82F6),
            onTap: () => _importProject(),
            isLoading: projectState.isImporting,
          ),
        ),
        if (projects.isNotEmpty) ...[
          const SizedBox(width: 12),
          _buildActionButton(
            icon: Icons.refresh,
            title: '刷新',
            color: const Color(0xFF8B5CF6),
            isSmall: true,
            onTap: () => ref.read(projectNotifierProvider).refreshProjects(),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
    bool isSmall = false,
  }) {
    return Container(
      height: 40, // 统一减小高度
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(10), // 减小圆角
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6, // 减小阴影
            offset: const Offset(0, 2), // 减小偏移
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: isLoading ? null : onTap,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 16, // 减小加载器尺寸
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5, // 减小线条粗细
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: isSmall ? 16 : 18), // 减小图标尺寸
                      if (!isSmall) ...[
                        const SizedBox(width: 6), // 减小间距
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12, // 减小字体
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12), // 减小内边距
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8), // 减小圆角
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16), // 减小图标
          const SizedBox(width: 8), // 减小间距
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 11, // 减小字体
              ),
              maxLines: 2, // 限制行数
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4), // 减小间距
          GestureDetector(
            onTap: () => ref.read(projectNotifierProvider).clearError(),
            child: const Icon(Icons.close, color: Color(0xFFEF4444), size: 14), // 减小图标
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
          SizedBox(height: 16),
          Text(
            '加载项目中...',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.collections_bookmark_outlined,
              size: 60,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '还没有作品',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '创建你的第一个积木作品吧！',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          _buildActionButton(
            icon: Icons.add,
            title: '新建项目',
            color: const Color(0xFF10B981),
            onTap: () => _createNewProject(),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitGrid(List<ProjectData> projects) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75, // 调整宽高比，让预览图更大
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) => _buildProjectCard(projects[index]),
    );
  }

  Widget _buildOptimizedLandscapeGrid(List<ProjectData> projects) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3列布局，卡片更大
        childAspectRatio: 1.0, // 调整为1:1比例，更好展示预览图
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) => _buildProjectCard(projects[index]), // 统一使用新设计
    );
  }
  

  Widget _buildLandscapeEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.collections_bookmark_outlined,
              size: 50,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '还没有作品',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击左侧"新建项目"开始创建你的第一个积木作品！',
            style: TextStyle(
              color: const Color(0xFF9CA3AF),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  Widget _buildProjectCard(ProjectData project) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openProject(project),
          onLongPress: () => _showProjectOptions(project),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 大尺寸预览图 - 占据卡片主要部分
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF374151),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: project.thumbnail.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          child: SizedBox.expand(
                            child: Image.network(
                              project.thumbnail,
                              fit: BoxFit.contain, // 完整显示，不遮挡
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.view_in_ar,
                                    color: Color(0xFF6B7280),
                                    size: 56,
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.view_in_ar,
                            color: Color(0xFF6B7280),
                            size: 56,
                          ),
                        ),
                ),
              ),
              
              // 信息区域 - 紧凑布局
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 项目名称
                    Text(
                      project.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // 项目描述
                    Text(
                      project.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 12,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 底部信息行 - 积木数量和时间
                    Row(
                      children: [
                        // 积木数量
                        Icon(
                          Icons.view_in_ar,
                          size: 12, // 减小图标
                          color: Colors.blue.shade300,
                        ),
                        const SizedBox(width: 3), // 减小间距
                        Text(
                          '${project.brickCount}',
                          style: TextStyle(
                            color: Colors.blue.shade300,
                            fontSize: 10, // 减小字体
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8), // 减小间距
                        // 分隔点
                        Container(
                          width: 2, // 减小宽度
                          height: 2, // 减小高度
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8), // 减小间距
                        // 时间
                        Icon(
                          Icons.access_time,
                          size: 12, // 减小图标
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(width: 3), // 减小间距
                        Expanded( // 使用Expanded让文本自适应剩余空间
                          child: Text(
                            _getRelativeTime(project.updatedAt),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 10, // 减小字体
                            ),
                            overflow: TextOverflow.ellipsis, // 防止溢出
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createNewProject() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LegoStudioPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _importProject() async {
    HapticFeedback.lightImpact();
    final project = await ref.read(projectNotifierProvider).importProject();
    
    if (project != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('项目导入成功！'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('项目导入失败'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  void _openProject(ProjectData project) async {
    HapticFeedback.lightImpact();
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LegoStudioPage(
          initialProject: project,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    
    // 如果有保存操作，刷新项目列表
    if (result == true) {
      ref.read(projectNotifierProvider).refreshProjects();
    }
  }

  void _showProjectOptions(ProjectData project) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // 允许滚动控制
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7, // 限制最大高度为屏幕70%
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                project.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              _buildOptionTile(
                icon: Icons.play_arrow,
                title: '打开项目',
                onTap: () {
                  Navigator.pop(context);
                  _openProject(project);
                },
              ),
              _buildOptionTile(
                icon: Icons.share,
                title: '导出项目',
                onTap: () async {
                  Navigator.pop(context);
                  final success = await ref.read(projectNotifierProvider).exportProject(project.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? '项目导出成功！' : '项目导出失败'),
                      backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  );
                },
              ),
              _buildOptionTile(
                icon: Icons.edit,
                title: '重命名',
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(project);
                },
              ),
              _buildOptionTile(
                icon: Icons.delete,
                title: '删除项目',
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(project);
                },
                isDestructive: true,
              ),
              const SizedBox(height: 20),
              // 底部安全区域
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDestructive 
                ? const Color(0xFFEF4444).withOpacity(0.1)
                : const Color(0xFF374151),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive ? const Color(0xFFEF4444) : Colors.white,
                size: 20,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isDestructive ? const Color(0xFFEF4444) : Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // 允许滚动
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6, // 限制最大高度
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '排序方式',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSortOption(ProjectSortMode.dateUpdated, '最近修改'),
                    _buildSortOption(ProjectSortMode.dateCreated, '创建时间'),
                    _buildSortOption(ProjectSortMode.name, '项目名称'),
                    _buildSortOption(ProjectSortMode.brickCount, '积木数量'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(ProjectSortMode mode, String title) {
    final currentMode = ref.watch(projectProvider).sortMode;
    final isSelected = currentMode == mode;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          ref.read(projectNotifierProvider).setSortMode(mode);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF374151),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(ProjectData project) {
    final controller = TextEditingController(text: project.name);
    
    showDialog(
      context: context,
      builder: (context) {
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        final screenSize = MediaQuery.of(context).size;
        final isLandscape = screenSize.width > screenSize.height;
        
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: isLandscape ? 10 : 20,
            bottom: keyboardHeight + (isLandscape ? 10 : 20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isLandscape ? 500 : double.infinity, // 横屏限制最大宽度
              maxHeight: isLandscape ? screenSize.height * 0.5 : screenSize.height * 0.4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.all(isLandscape ? 12 : 16),
            child: isLandscape
                ? _buildLandscapeRenameContent(controller, project)
                : _buildPortraitRenameContent(controller, project),
          ),
        );
      },
    );
  }
  
  // 横屏布局 - 紧凑的横向排列
  Widget _buildLandscapeRenameContent(TextEditingController controller, ProjectData project) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 标题（紧凑）
        const Text(
          '重命名',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 16),
        
        // 输入框（扩展占据剩余空间）
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: '输入新名称',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF374151)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3B82F6)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              isDense: true,
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                ref.read(projectNotifierProvider).updateProject(
                  project.id,
                  name: value,
                );
                Navigator.pop(context);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        
        // 按钮（紧凑）
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            '取消',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              ref.read(projectNotifierProvider).updateProject(
                project.id,
                name: controller.text,
              );
              Navigator.pop(context);
            }
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            '确定',
            style: TextStyle(color: Color(0xFF3B82F6), fontSize: 13),
          ),
        ),
      ],
    );
  }
  
  // 竖屏布局 - 传统的纵向排列
  Widget _buildPortraitRenameContent(TextEditingController controller, ProjectData project) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        const Text(
          '重命名项目',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 16),
        
        // 输入框
        TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: '输入新名称',
            hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF374151)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF3B82F6)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            isDense: true,
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              ref.read(projectNotifierProvider).updateProject(
                project.id,
                name: value,
              );
              Navigator.pop(context);
            }
          },
        ),
        const SizedBox(height: 16),
        
        // 按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '取消',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  ref.read(projectNotifierProvider).updateProject(
                    project.id,
                    name: controller.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text(
                '确定',
                style: TextStyle(color: Color(0xFF3B82F6)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDeleteDialog(ProjectData project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        title: const Text(
          '删除项目',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            '确定要删除项目"${project.name}"吗？\n此操作不可撤销。',
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '取消',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(projectNotifierProvider).deleteProject(project.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('项目已删除'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            },
            child: const Text(
              '删除',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  String _getSortModeText(ProjectSortMode mode) {
    switch (mode) {
      case ProjectSortMode.name:
        return '名称';
      case ProjectSortMode.dateCreated:
        return '创建';
      case ProjectSortMode.dateUpdated:
        return '修改';
      case ProjectSortMode.brickCount:
        return '积木';
    }
  }
}
