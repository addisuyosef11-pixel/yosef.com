import 'package:flutter/material.dart';
import 'dart:async'; // Add this import for Timer
import 'dart:io'; // Add this import for File
import 'package:intl/intl.dart';
import 'api_service.dart';

// Rename the class to avoid conflict
class VideoNewsPage extends StatefulWidget {
  final String token;
  
  const VideoNewsPage({Key? key, required this.token}) : super(key: key);
  
  @override
  State<VideoNewsPage> createState() => _VideoNewsPageState();
}

class _VideoNewsPageState extends State<VideoNewsPage> {
  List<dynamic> _videos = [];
  List<dynamic> _featuredVideos = [];
  bool _isLoading = true;
  bool _isLoadingFeatured = true;
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  final List<String> _categories = [
    'All',
    'Trending',
    'Entertainment',
    'Education',
    'Sports',
    'Technology',
    'Music',
    'Gaming'
  ];

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _loadFeaturedVideos();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadVideos({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() => _isLoading = true);
      _currentPage = 1;
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final videos = await ApiService.getVideoList(
        token: widget.token,
        page: _currentPage,
        pageSize: 10,
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );

      if (!loadMore) {
        _videos = videos;
      } else {
        _videos.addAll(videos);
      }

      _hasMore = videos.length == 10; // Assuming 10 items per page
      _currentPage++;
      
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      print('Error loading videos: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      _showErrorSnackBar('Failed to load videos');
    }
  }

  Future<void> _loadFeaturedVideos() async {
    setState(() => _isLoadingFeatured = true);
    
    try {
      final featured = await ApiService.getFeaturedVideos(
        token: widget.token,
        page: 1,
      );
      setState(() {
        _featuredVideos = featured;
        _isLoadingFeatured = false;
      });
    } catch (e) {
      print('Error loading featured videos: $e');
      setState(() => _isLoadingFeatured = false);
    }
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore && _hasMore) {
      _loadVideos(loadMore: true);
    }
  }

  void _onSearch(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadVideos();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLike(int videoId, int index) async {
    try {
      final result = await ApiService.likeVideo(
        token: widget.token,
        videoId: videoId,
      );
      
      if (mounted) {
        setState(() {
          final video = _videos[index] as Map<String, dynamic>;
          final currentLikes = video['likes'] ?? 0;
          video['likes'] = currentLikes + 1;
          video['user_has_liked'] = true;
        });
        _showSuccessSnackBar('Liked!');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to like video');
    }
  }

  Future<void> _handleView(int videoId) async {
    try {
      await ApiService.incrementVideoViews(
        token: widget.token,
        videoId: videoId,
      );
    } catch (e) {
      print('Error incrementing views: $e');
    }
  }

  void _openVideoDetail(Map<String, dynamic> video) async {
    // First increment views
    await _handleView(video['id']);
    
    // Then navigate to video detail page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoDetailPage(
          token: widget.token,
          video: video,
        ),
      ),
    );
  }

  // Simple image widget to replace CachedNetworkImage
  Widget _buildNetworkImage(String url, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
    return Image.network(
      url,
      height: height,
      width: width,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.error, color: Colors.grey),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadVideos(),
            _loadFeaturedVideos(),
          ]);
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: true,
              floating: true,
              expandedHeight: 200,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF4F46E5),
                        const Color(0xFF4F46E5).withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          'Video News',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Watch latest videos and updates',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Search Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                const Icon(Icons.search, color: Colors.grey),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: const InputDecoration(
                                      hintText: 'Search videos...',
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(color: Colors.grey),
                                    ),
                                    onChanged: _onSearch,
                                  ),
                                ),
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      _loadVideos();
                                    },
                                  ),
                                const SizedBox(width: 10),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Categories
            SliverToBoxAdapter(
              child: Container(
                height: 60,
                color: Colors.white,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF4F46E5),
                        backgroundColor: Colors.grey[100],
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? category : 'All';
                          });
                          _loadVideos();
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Featured Videos Section
            if (_featuredVideos.isNotEmpty && !_isLoadingFeatured)
              SliverToBoxAdapter(
                child: _buildFeaturedSection(),
              ),

            // Videos Grid
            if (_isLoading && _videos.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF4F46E5)),
                      const SizedBox(height: 20),
                      Text(
                        'Loading videos...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_videos.isEmpty && !_isLoading)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam_off,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No videos found',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Try a different search or category',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadVideos,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.7,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < _videos.length) {
                        final video = _videos[index] as Map<String, dynamic>;
                        return _buildVideoCard(video, index);
                      } else if (_isLoadingMore) {
                        return Container(
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(color: Color(0xFF4F46E5)),
                        );
                      } else {
                        return const SizedBox();
                      }
                    },
                    childCount: _videos.length + (_isLoadingMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UploadVideoPage(token: widget.token),
            ),
          );
        },
        backgroundColor: const Color(0xFF4F46E5),
        child: const Icon(Icons.video_call, color: Colors.white),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Featured Videos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = 'Trending';
                  });
                  _loadVideos();
                },
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _featuredVideos.length,
            itemBuilder: (context, index) {
              final video = _featuredVideos[index] as Map<String, dynamic>;
              return GestureDetector(
                onTap: () => _openVideoDetail(video),
                child: Container(
                  width: 300,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(
                        video['thumbnail'] ?? 'https://via.placeholder.com/300x200',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video['title'] ?? 'No Title',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.visibility, size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              '${video['views'] ?? 0}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.schedule, size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(video['duration'] ?? 0),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video, int index) {
    return GestureDetector(
      onTap: () => _openVideoDetail(video),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  children: [
                    _buildNetworkImage(
                      video['thumbnail'] ?? 'https://via.placeholder.com/300x200',
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatDuration(video['duration'] ?? 0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Video Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    video['title'] ?? 'No Title',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  
                  // Uploader and Date
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage(
                          video['uploader_avatar'] ?? 'https://via.placeholder.com/100',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          video['uploader_name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Stats and Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Views
                      Row(
                        children: [
                          const Icon(Icons.visibility, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${video['views'] ?? 0}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      
                      // Likes
                      GestureDetector(
                        onTap: () => _handleLike(video['id'], index),
                        child: Row(
                          children: [
                            Icon(
                              (video['user_has_liked'] ?? false) ? Icons.favorite : Icons.favorite_border,
                              size: 14,
                              color: (video['user_has_liked'] ?? false) ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${video['likes'] ?? 0}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
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
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final remainingSeconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }
}

// ==========================
// VIDEO DETAIL PAGE
// ==========================

class VideoDetailPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> video;
  
  const VideoDetailPage({
    Key? key,
    required this.token,
    required this.video,
  }) : super(key: key);
  
  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  bool _isLiked = false;
  bool _isLoading = false;
  Map<String, dynamic>? _videoDetails;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.video['user_has_liked'] ?? false;
    _loadVideoDetails();
  }

  Future<void> _loadVideoDetails() async {
    try {
      setState(() => _isLoading = true);
      final details = await ApiService.getVideoDetail(
        token: widget.token,
        videoId: widget.video['id'],
      );
      setState(() {
        _videoDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading video details: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLike() async {
    try {
      final result = await ApiService.likeVideo(
        token: widget.token,
        videoId: widget.video['id'],
      );
      
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          if (_isLiked) {
            widget.video['likes'] = (widget.video['likes'] ?? 0) + 1;
          } else {
            widget.video['likes'] = (widget.video['likes'] ?? 0) - 1;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLiked ? 'Liked!' : 'Like removed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to like video'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDislike() async {
    try {
      await ApiService.dislikeVideo(
        token: widget.token,
        videoId: widget.video['id'],
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disliked'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to dislike video'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final video = _videoDetails ?? widget.video;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    video['thumbnail'] ?? 'https://via.placeholder.com/800x450',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    video['title'] ?? 'No Title',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Uploader Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                          video['uploader_avatar'] ?? 'https://via.placeholder.com/100',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video['uploader_name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatDate(video['uploaded_at']),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(Icons.visibility, '${video['views'] ?? 0} Views'),
                      _buildStatItem(Icons.favorite, '${video['likes'] ?? 0} Likes'),
                      _buildStatItem(Icons.comment, '${video['comments'] ?? 0} Comments'),
                      _buildStatItem(Icons.schedule, _formatDuration(video['duration'] ?? 0)),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Actions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _handleLike,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLiked ? Colors.red : Colors.grey[200],
                          foregroundColor: _isLiked ? Colors.white : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border),
                        label: Text(_isLiked ? 'Liked' : 'Like'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _handleDislike,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.thumb_down),
                        label: const Text('Dislike'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Share functionality
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 25),
                  
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    video['description'] ?? 'No description available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 25),
                  
                  // Tags
                  if (video['tags'] != null && video['tags'].isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tags',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (video['tags'] as List).map<Widget>((tag) {
                            return Chip(
                              label: Text(tag.toString()),
                              backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF4F46E5), size: 24),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final remainingSeconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

// ==========================
// UPLOAD VIDEO PAGE
// ==========================

class UploadVideoPage extends StatefulWidget {
  final String token;
  
  const UploadVideoPage({Key? key, required this.token}) : super(key: key);
  
  @override
  State<UploadVideoPage> createState() => _UploadVideoPageState();
}

class _UploadVideoPageState extends State<UploadVideoPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagsController = TextEditingController();
  
  File? _videoFile;
  File? _thumbnailFile;
  bool _isPrivate = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final List<String> _categories = [
    'Entertainment',
    'Education',
    'Sports',
    'Technology',
    'Music',
    'Gaming',
    'News',
    'Lifestyle'
  ];

  Future<void> _pickVideo() async {
    // Simple placeholder for video picking
    // You can implement actual file picking later
    _showMessage('Video picker will be implemented');
  }

  Future<void> _pickThumbnail() async {
    // Simple placeholder for thumbnail picking
    _showMessage('Thumbnail picker will be implemented');
  }

  Future<void> _uploadVideo() async {
    if (_videoFile == null) {
      _showError('Please select a video file');
      return;
    }
    
    if (_titleController.text.isEmpty) {
      _showError('Please enter a title');
      return;
    }
    
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Split tags by comma
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final result = await ApiService.uploadVideo(
        token: widget.token,
        videoFile: _videoFile!,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _categoryController.text.isNotEmpty ? _categoryController.text : null,
        tags: tags.isNotEmpty ? tags : null,
        isPrivate: _isPrivate,
        thumbnailFile: _thumbnailFile,
      );

      if (mounted) {
        setState(() => _isUploading = false);
        
        if (result.containsKey('success') && result['success'] == true) {
          _showSuccess('Video uploaded successfully!');
          Navigator.pop(context);
        } else {
          _showError(result['error']?.toString() ?? 'Upload failed');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showError('Upload error: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Video'),
        backgroundColor: const Color(0xFF4F46E5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video Selection
              GestureDetector(
                onTap: _pickVideo,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: _videoFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.video_library,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Tap to select video',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'MP4, MOV, AVI up to 500MB',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            // Video preview or thumbnail
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.black,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.play_circle_filled,
                                  size: 60,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                  onPressed: () {
                                    setState(() => _videoFile = null);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Thumbnail Selection
              GestureDetector(
                onTap: _pickThumbnail,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: _thumbnailFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Select thumbnail (optional)',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              _thumbnailFile!,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white, size: 16),
                                  onPressed: () {
                                    setState(() => _thumbnailFile = null);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 25),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Video Title *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _categoryController.text.isNotEmpty ? _categoryController.text : null,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoryController.text = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 16),

              // Tags
              TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: 'Tags (comma separated)',
                  hintText: 'e.g., flutter, tutorial, mobile',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 16),

              // Privacy Toggle
              Row(
                children: [
                  const Icon(Icons.lock, color: Colors.grey),
                  const SizedBox(width: 10),
                  const Text('Private Video'),
                  const Spacer(),
                  Switch(
                    value: _isPrivate,
                    activeColor: const Color(0xFF4F46E5),
                    onChanged: (value) {
                      setState(() => _isPrivate = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Upload Button
              if (_isUploading)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.grey[200],
                      color: const Color(0xFF4F46E5),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Uploading... ${(_uploadProgress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: _uploadVideo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Upload Video',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}