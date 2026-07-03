import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeDesktopLayout extends StatelessWidget {
  final VoidCallback? onTriggerCrash;

  const HomeDesktopLayout({super.key, this.onTriggerCrash});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Row(
        children: [
          // Left Navigation Sidebar (Expanded)
          Container(
            width: 260,
            color: const Color(0xFF1E1E2F),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Icon(Icons.explore, color: Color(0xFF6366F1), size: 32),
                      SizedBox(width: 12),
                      Text(
                        'ChillGo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      _buildSidebarItem(Icons.dashboard, 'Dashboard', true),
                      _buildSidebarItem(
                        Icons.groups,
                        'My Crews',
                        false,
                        onTap: () => context.push('/crews'),
                      ),
                      _buildSidebarItem(
                        Icons.explore,
                        'Outings',
                        false,
                        enabled: false,
                      ),
                      _buildSidebarItem(
                        Icons.settings,
                        'Settings',
                        false,
                        enabled: false,
                      ),
                    ],
                  ),
                ),
                if (onTriggerCrash != null)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ElevatedButton.icon(
                      onPressed: onTriggerCrash,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.bug_report),
                      label: const Text('Simulate Crash'),
                    ),
                  ),
              ],
            ),
          ),
          const VerticalDivider(
            thickness: 1,
            width: 1,
            color: Color(0xFF2E2E4F),
          ),
          // Middle Content Panel (Main Dashboard)
          Expanded(
            flex: 3,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to ChillGo Desktop',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your central coordination hub for all active crews and outings.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 15),
                    ),
                    const SizedBox(height: 32),
                    _buildBannerCard(),
                    const SizedBox(height: 32),
                    const Text(
                      'Management Actions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionGrid(context),
                  ],
                ),
              ),
            ),
          ),
          const VerticalDivider(
            thickness: 1,
            width: 1,
            color: Color(0xFF2E2E4F),
          ),
          // Right Panel (Status & Activity)
          Container(
            width: 340,
            color: const Color(0xFF131324),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Crew Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildPanelLink(
                  context,
                  icon: Icons.groups,
                  title: 'My Crews',
                  subtitle: 'Create, invite, and manage members.',
                  route: '/crews',
                ),
                const SizedBox(height: 12),
                _buildPanelLink(
                  context,
                  icon: Icons.mail_outline,
                  title: 'Invitations',
                  subtitle: 'Accept or reject crew invitations.',
                  route: '/invitations',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    IconData icon,
    String title,
    bool isSelected, {
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF6366F1).withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        enabled: enabled,
        onTap: enabled ? onTap : null,
        leading: Icon(
          icon,
          color: isSelected
              ? const Color(0xFF6366F1)
              : enabled
              ? Colors.grey[400]
              : Colors.grey[700],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : enabled
                ? Colors.grey[400]
                : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.explore, color: Colors.white, size: 48),
          SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore New Boundaries',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'No active outings are running at the moment. Invite members to a crew and propose a new outing location to begin coordination.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 1.8,
      children: [
        _buildActionCard(
          icon: Icons.groups,
          title: 'My Crews',
          subtitle: 'Create, invite, and coordinate crew groups.',
          color: const Color(0xFF3B82F6),
          onTap: () {
            context.push('/crews');
          },
        ),
        _buildActionCard(
          icon: Icons.add_box,
          title: 'New Outing',
          subtitle: 'Propose a new meetup destination and voting rules.',
          color: const Color(0xFF10B981),
          onTap: () {},
        ),
        _buildActionCard(
          icon: Icons.info,
          title: 'Details View',
          subtitle: 'Check internal repository and mock configurations.',
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2E2E4F)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelLink(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2E2E4F)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.12),
              child: Icon(icon, color: const Color(0xFF6366F1), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
