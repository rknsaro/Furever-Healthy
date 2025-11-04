import 'package:flutter/material.dart';
import 'package:fureverhealthy/my_pets/all_pets.dart'; // ✅ Import AllPetsPage
import 'account_session.dart';

const _mint = Color(0xFF6F994A);
const _bg = Color(0xFFF9F9F9);

class UserProfTab extends StatefulWidget {
  const UserProfTab({super.key});

  @override
  State<UserProfTab> createState() => _UserProfTabState();
}

class _UserProfTabState extends State<UserProfTab> {
  String _selectedTile = ''; // Track which tile is selected

  Widget _buildProfileTile({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
    IconData? trailingIcon,
  }) {
    final bool isSelected = _selectedTile == title;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _selectedTile = title;
        });
        onTap();
      },
      splashColor: _mint.withOpacity(0.2),
      hoverColor: _mint.withOpacity(0.1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? _mint : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: _mint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
              if (trailingIcon != null)
                Icon(
                  trailingIcon,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mint Header for Section
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: _mint,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white, // ✅ White text on mint background
              ),
            ),
          ),
          // Tiles inside
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Profile Icon with Label
            Center(
              child: Column(
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      // shape: BoxShape.circle,
                      // border: Border.all(color: _mint, width: 3),
                      image: const DecorationImage(
                        image: AssetImage('assets/user_prof.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // const SizedBox(height: 10),
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _mint,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),

            // --- Account Section ---
            _buildSection(
              title: 'Account',
              children: [
                _buildProfileTile(
                  context: context,
                  title: 'Edit Profile',
                  trailingIcon: Icons.edit_outlined,
                  onTap: () {},
                ),
                _buildProfileTile(
                  context: context,
                  title: 'Account & Session',
                  trailingIcon: Icons.arrow_forward_ios,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AccountSessionPage(),
                      ),
                    );
                  },
                ),
              ],
            ),

            // --- Pets Section ---
            _buildSection(
              title: 'Pets',
              children: [
                _buildProfileTile(
                  context: context,
                  title: 'My Pets',
                  trailingIcon: Icons.arrow_forward_ios,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllPetsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),

            // --- Others Section ---
            _buildSection(
              title: 'Others',
              children: [
                _buildProfileTile(
                  context: context,
                  title: 'Subscriptions',
                  trailingIcon: Icons.arrow_forward_ios,
                  onTap: () {},
                ),
                _buildProfileTile(
                  context: context,
                  title: 'Feedback',
                  trailingIcon: Icons.arrow_forward_ios,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
