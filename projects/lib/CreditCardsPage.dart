import 'package:flutter/material.dart';
import 'package:projects/Model/credit_card.dart';
import 'package:projects/services/api_service.dart';
import 'package:projects/EditCreditCardPage.dart';
import 'package:projects/AddCreditCardModal.dart';


class CreditCardsPage extends StatefulWidget {
  final Function onCreditCardAdded; // Callback for when a card is added

  const CreditCardsPage({super.key, required this.onCreditCardAdded});

  @override
  State<CreditCardsPage> createState() => _CreditCardsPageState();
}

class _CreditCardsPageState extends State<CreditCardsPage> {
  List<CreditCard> _allCreditCards = []; // Original fetched list
  List<CreditCard> _validCreditCards = [];
  List<CreditCard> _soonExpiringCreditCards = [];
  List<CreditCard> _expiredCreditCards = [];

  bool _isLoading = true;
  Map<int, bool> _selectedCreditCards = {}; // For potential future delete mode

  @override
  void initState() {
    super.initState();
    _loadCreditCards();
  }

  // Helper to parse MM/YY string to a DateTime object representing the first day of that month
  DateTime _parseExpiryDateToMonthStart(String expiryDate) {
    final parts = expiryDate.split('/');
    final month = int.parse(parts[0]);
    // Assuming 2-digit year is current century (e.g., '25' -> 2025)
    final year = 2000 + int.parse(parts[1]);
    return DateTime(year, month, 1); // First day of the expiry month
  }

  Future<void> _loadCreditCards() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final fetchedCards = await ApiService.fetchCreditCards();
      if (mounted) {
        // Clear previous categorizations
        _validCreditCards.clear();
        _soonExpiringCreditCards.clear();
        _expiredCreditCards.clear();
        _allCreditCards = fetchedCards; // Store original for total count check

        final now = DateTime.now();
        final currentMonthStart = DateTime(now.year, now.month, 1);
        // Cards expiring within 3 months from the start of the current month
        // For example, if now is June 10, 2025:
        // currentMonthStart = June 1, 2025
        // threeMonthsFromCurrentMonthStart = September 1, 2025
        // A card expiring in August 2025 would be "soon-to-expire".
        final threeMonthsFromCurrentMonthStart = DateTime(now.year, now.month + 5, 1);


        for (final card in fetchedCards) {
          try {
            final expiryDateTimeStartOfMonth = _parseExpiryDateToMonthStart(card.expiryDate);

            // Check if expired: expiry month is before the current month
            if (expiryDateTimeStartOfMonth.isBefore(currentMonthStart)) {
              _expiredCreditCards.add(card);
            } else {
              // Check if soon-to-expire: expiry month is from current month up to 3 months from now
              // (e.g., if current is June, cards expiring June, July, August are soon-to-expire)
              if (expiryDateTimeStartOfMonth.isBefore(threeMonthsFromCurrentMonthStart)) {
                _soonExpiringCreditCards.add(card);
              } else {
                _validCreditCards.add(card);
              }
            }
          } catch (e) {
            print('Error parsing expiry date for card ${card.id}: ${card.expiryDate}, error: $e');
            // If parsing fails, treat as valid to avoid breaking UI, or categorize differently if needed
            _validCreditCards.add(card);
          }
        }

        setState(() {
          // Update state after categorization
        });
      }
    } catch (e) {
      print('Error loading credit cards: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load credit cards: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteSelectedCreditCards() async {
    List<int> idsToDelete = _selectedCreditCards.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();

    if (idsToDelete.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No credit cards selected for deletion.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete ${idsToDelete.length} selected credit card(s)?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    for (int id in idsToDelete) {
      final success = await ApiService.deleteCreditCard(id);
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete card with ID: $id")),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _selectedCreditCards.clear(); // Clear selections
        // Potentially toggle off delete mode if implemented
      });
      await _loadCreditCards(); // Reload the list after deletion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Deleted ${idsToDelete.length} credit card(s)")),
      );
    }
  }

  // Helper to mask card number for display
  String _maskCardNumber(String cardNumber) {
    if (cardNumber.length < 4) return cardNumber;
    return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
  }

  // Helper for section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // Helper for "No cards" message
  Widget _buildNoCardsMessage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          "No cards in this category.",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  // Helper to build a list of cards for a given category
  Widget _buildCardList(List<CreditCard> cards, {required bool showWarning, bool isExpired = false}) {
    if (cards.isEmpty) {
      return _buildNoCardsMessage();
    }
    return ListView.builder(
      shrinkWrap: true, // Important for nested list views inside SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Disable scrolling for nested list views
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditCreditCardPage(creditCard: card),
                ),
              );
              if (updated == true) {
                _loadCreditCards(); // Refresh the list if updated/deleted
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Credit Card updated or deleted")),
                  );
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        card.cardHolderName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isExpired ? Colors.grey : Colors.black, // Grey out expired cards
                        ),
                      ),
                      if (showWarning) // Show warning icon for soon-to-expire cards
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _maskCardNumber(card.cardNumber),
                    style: TextStyle(
                      fontSize: 16,
                      color: isExpired ? Colors.grey[600] : Colors.grey[700],
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Expires: ${card.expiryDate}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isExpired ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                      // Display card type icon if available
                      if (card.type != null && card.type!.isNotEmpty)
                        _getCardTypeIcon(card.type!),
                    ],
                  ),
                  if (card.notes != null && card.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Notes: ${card.notes}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isExpired ? Colors.grey[500] : Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView( // Make the entire body scrollable
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align content to start
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 25, 0, 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Credit Cards",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            _isLoading
                ? const Center(child: Padding(
              padding: EdgeInsets.all(50.0),
              child: CircularProgressIndicator(),
            ))
                : _allCreditCards.isEmpty // Check if total cards are empty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text(
                  "💳 No credit cards stored yet!",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
                : Column( // This Column will contain the categorized lists
              children: [
                // Valid Cards Section
                _buildSectionHeader("Valid Cards"),
                _buildCardList(_validCreditCards, showWarning: false),

                // Soon-to-Expire Cards Section
                _buildSectionHeader("Soon-to-Expire Cards"),
                _buildCardList(_soonExpiringCreditCards, showWarning: true),

                // Expired Cards Section
                _buildSectionHeader("Expired Cards"),
                _buildCardList(_expiredCreditCards, showWarning: false, isExpired: true),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // Allows the modal to take full height
            builder: (context) => AddCreditCardModal(
              onAdded: () {
                _loadCreditCards(); // Reload cards after a new one is added
                widget.onCreditCardAdded(); // Trigger the parent callback
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Helper to return an icon based on card type
  Widget _getCardTypeIcon(String type) {
    String lowerType = type.toLowerCase();
    IconData iconData;
    Color iconColor;

    if (lowerType.contains('visa')) {
      iconData = Icons.credit_card; // Or a specific Visa icon if you have one
      iconColor = Colors.blue;
    } else if (lowerType.contains('mastercard')) {
      iconData = Icons.credit_card; // Or a specific Mastercard icon
      iconColor = Colors.orange;
    } else if (lowerType.contains('amex') || lowerType.contains('american express')) {
      iconData = Icons.credit_card; // Or a specific Amex icon
      iconColor = Colors.green;
    } else {
      iconData = Icons.credit_card; // Default icon
      iconColor = Colors.grey;
    }
    return Icon(iconData, color: iconColor, size: 24);
  }
}