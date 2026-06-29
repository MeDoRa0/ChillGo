import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeTabletLayout extends StatefulWidget {
  final VoidCallback? onTriggerCrash;

  const HomeTabletLayout({super.key, this.onTriggerCrash});

  @override
  State<HomeTabletLayout> createState() => _HomeTabletLayoutState();
}

class _HomeTabletLayoutState extends State<HomeTabletLayout> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Row(
        children: [
          // Left Sidebar Navigation
          NavigationRail(
            backgroundColor: const Color(0xFF1E1E2F),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              // Only implemented destinations (Dashboard = 0) can be selected.
              if (index == 0) setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            unselectedIconTheme: const IconThemeData(color: Colors.grey),
            selectedIconTheme: const IconThemeData(color: Color(0xFF6366F1)),
            unselectedLabelTextStyle: const TextStyle(color: Colors.grey, fontSize: 11),
            selectedLabelTextStyle: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 11),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.groups, color: Colors.grey),
                label: Text('Crews'),
                disabled: true,
              ),
              NavigationRailDestination(
                icon: Icon(Icons.explore, color: Colors.grey),
                label: Text('Outings'),
                disabled: true,
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1, color: Color(0xFF2E2E4F)),
          // Main Content Area
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ChillGo Tablet Dashboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Manage your crews and upcoming plans.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        if (widget.onTriggerCrash != null)
                          ElevatedButton.icon(
                            onPressed: widget.onTriggerCrash,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.bug_report),
                            label: const Text('Simulate Crash'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _buildStatusCard(),
                                const SizedBox(height: 20),
                                Expanded(child: _buildGridActions(context)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 2,
                            child: _buildCrewsSidebar(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.explore, color: Colors.white, size: 36),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Quiet on the Outing Front',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'No active outings right now. Ready to schedule the next meetup?',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.6,
      children: [
        _buildActionCard(
          icon: Icons.groups,
          title: 'My Crews',
          subtitle: 'Manage members and coordinates',
          color: const Color(0xFF3B82F6),
          onTap: () {},
        ),
        _buildActionCard(
          icon: Icons.add_box,
          title: 'New Outing',
          subtitle: 'Plan location & voting schedule',
          color: const Color(0xFF10B981),
          onTap: () {},
        ),
        _buildActionCard(
          icon: Icons.info,
          title: 'Details View',
          subtitle: 'Inspect mock configurations',
          color: const Color(0xFFF59E0B),
          onTap: () {
            context.push('/details');
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2E2E4F)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrewsSidebar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E4F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Crews',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildCrewItem('Friday Night Coding', '5 members'),
                _buildCrewItem('Coffee Lovers', '3 members'),
                _buildCrewItem('Weekend Hikers', '8 members'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrewItem(String name, String members) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
            child: const Icon(Icons.group, color: Color(0xFF6366F1), size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                members,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
