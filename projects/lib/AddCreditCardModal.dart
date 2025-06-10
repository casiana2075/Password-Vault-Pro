import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for TextInputFormatter
import 'package:projects/services/api_service.dart';
import 'package:projects/utils/credit_card_preview.dart'; // Import the new preview widget

class AddCreditCardModal extends StatefulWidget {
  final Function onAdded;

  const AddCreditCardModal({super.key, required this.onAdded});

  @override
  State<AddCreditCardModal> createState() => _AddCreditCardModalState();
}

class _AddCreditCardModalState extends State<AddCreditCardModal> {
  final TextEditingController _cardHolderNameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;
  String? _selectedCardType; // State variable for the selected card type

  // Map of card types to their typical number lengths
  final Map<String, int> _cardTypeLengths = {
    'Visa': 16,
    'Mastercard': 16,
    'American Express': 15,
    'Discover': 16,
    'JCB': 16, // Assuming 16 for JCB, common length
    'Diners Club': 14, // Common length for Diners Club
    'UnionPay': 19, // UnionPay can be up to 19
  };

  @override
  void initState() {
    super.initState();
    // Add listeners to controllers to trigger rebuilds for the preview
    _cardHolderNameController.addListener(_updatePreview);
    _cardNumberController.addListener(_updatePreview);
    _expiryDateController.addListener(_updatePreview);
  }

  void _updatePreview() {
    // Only rebuild if the widget is mounted to avoid errors after dispose
    if (mounted) {
      setState(() {
        // State update will trigger the CreditCardPreview to rebuild
      });
    }
  }

  @override
  void dispose() {
    _cardHolderNameController.removeListener(_updatePreview);
    _cardNumberController.removeListener(_updatePreview);
    _expiryDateController.removeListener(_updatePreview);

    _cardHolderNameController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addCreditCard() async {
    if (_cardHolderNameController.text.isEmpty ||
        _cardNumberController.text.isEmpty ||
        _expiryDateController.text.isEmpty ||
        _cvvController.text.isEmpty ||
        _selectedCardType == null) { // Added check for selected card type
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ApiService.addCreditCard(
        cardHolderName: _cardHolderNameController.text,
        cardNumber: _cardNumberController.text.replaceAll(' ', ''), // Remove spaces before sending
        expiryDate: _expiryDateController.text,
        cvv: _cvvController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        type: _selectedCardType, // Use the selected card type from dropdown
      );

      if (success) {
        widget.onAdded(); // Callback to parent to refresh list
        if (mounted) {
          Navigator.of(context).pop(); // Close the modal
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Credit Card added successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add credit card.')),
          );
        }
      }
    } catch (e) {
      print('Error adding credit card: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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

  // Helper widget for consistent text field styling
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    int? maxLength,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        obscureText: obscureText,
        maxLength: maxLength,
        maxLines: maxLines,
        decoration: InputDecoration(
          counterText: "", // Hide character counter
          prefixIcon: Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 5, 5),
            child: Icon(
              icon,
              color: const Color.fromARGB(255, 82, 101, 120),
            ),
          ),
          filled: true,
          contentPadding: const EdgeInsets.all(16),
          labelText: labelText, // Use labelText instead of hintText for floating label
          labelStyle: const TextStyle(
              color: Color.fromARGB(255, 82, 101, 120), fontWeight: FontWeight.w500),
          fillColor: const Color.fromARGB(247, 232, 235, 237),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(35),
          ),
        ),
        style: const TextStyle(),
      ),
    );
  }

  // Helper widget for section headings
  Widget _buildFormHeading(String text) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 10, 10, 10),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // Determine the max length and placeholder for card number based on selected type
    int? cardNumberDigitsMaxLength = _selectedCardType != null
        ? _cardTypeLengths[_selectedCardType]
        : 19; // Default max length (e.g., UnionPay up to 19)
    String cardNumberLabelText = _selectedCardType != null
        ? 'Card Number (e.g., ${'X' * (_cardTypeLengths[_selectedCardType] ?? 16)})'
        : 'Card Number';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 10,
        right: 10,
        top: 10,
      ),
      child: SingleChildScrollView( // Added SingleChildScrollView to prevent overflow
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: screenWidth * 0.4,
                height: 5,
                decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 156, 156, 156),
                    borderRadius: BorderRadius.circular(35)),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.center,
              child: Text(
                "Add New Credit Card",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
              ),
            ),
            const SizedBox(height: 20),

            // Credit Card Preview Widget
            CreditCardPreview(
              cardNumber: _cardNumberController.text,
              cardHolderName: _cardHolderNameController.text,
              expiryDate: _expiryDateController.text,
              cardType: _selectedCardType ?? '',
            ),
            const SizedBox(height: 20), // Add some space after preview

            // Card Type Dropdown
            _buildFormHeading("Card Type"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DropdownButtonFormField<String>(
                value: _selectedCardType,
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.fromLTRB(20, 5, 5, 5),
                    child: Icon(
                      Icons.category,
                      color: Color.fromARGB(255, 82, 101, 120),
                    ),
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.all(16),
                  labelText: 'Select Card Type',
                  labelStyle: const TextStyle(
                      color: Color.fromARGB(255, 82, 101, 120),
                      fontWeight: FontWeight.w500),
                  fillColor: const Color.fromARGB(247, 232, 235, 237),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(35),
                  ),
                ),
                items: _cardTypeLengths.keys.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCardType = newValue;
                    _updatePreview(); // Update preview when card type changes
                  });
                },
              ),
            ),
            const SizedBox(height: 10),

            _buildFormHeading("Card Holder Name"),
            _buildTextField(
              controller: _cardHolderNameController,
              labelText: 'Card Holder Name',
              icon: Icons.person,
              maxLength: 50,
            ),
            const SizedBox(height: 10),

            _buildFormHeading("Card Number"),
            _buildTextField(
              controller: _cardNumberController,
              labelText: cardNumberLabelText, // Dynamic label text
              icon: Icons.credit_card,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(cardNumberDigitsMaxLength), // Dynamic max length of digits
                _CardNumberInputFormatter(),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormHeading("Expiry Date"),
                      _buildTextField(
                        controller: _expiryDateController,
                        labelText: 'MM/YY',
                        icon: Icons.date_range,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          // Only use _ExpiryDateInputFormatter here
                          _ExpiryDateInputFormatter(),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormHeading("CVV"),
                      _buildTextField(
                        controller: _cvvController,
                        labelText: 'CVV',
                        icon: Icons.vpn_key,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        maxLength: 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildFormHeading("Notes (Optional)"),
            _buildTextField(
              controller: _notesController,
              labelText: 'Notes',
              icon: Icons.note,
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
              height: MediaQuery.of(context).size.height * 0.055,
              width: screenWidth * 0.5,
              child: ElevatedButton(
                onPressed: _addCreditCard,
                style: ButtonStyle(
                  elevation: const WidgetStatePropertyAll(5),
                  shadowColor: const WidgetStatePropertyAll(Color.fromARGB(255, 55, 114, 255)),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                      side: const BorderSide(color: Color.fromARGB(255, 55, 114, 255)),
                    ),
                  ),
                  backgroundColor: const WidgetStatePropertyAll(Color.fromARGB(255, 55, 114, 255)),
                ),
                child: const Text(
                  'Add Credit Card',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// Custom TextInputFormatter for Credit Card Number spacing (e.g., XXXX XXXX XXXX XXXX)
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    var text = newValue.text.replaceAll(' ', ''); // Remove existing spaces for consistent processing

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

// Custom TextInputFormatter for Expiry Date (MM/YY)
class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    // 1. Filter to digits only
    final String newDigits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // 2. Limit to 4 digits (MMYY)
    String limitedDigits = newDigits;
    if (limitedDigits.length > 4) {
      limitedDigits = limitedDigits.substring(0, 4);
    }

    // --- Month Validation ---
    if (limitedDigits.isNotEmpty) {
      if (limitedDigits.length == 1) {
        // If the first digit is > 1, it implies an invalid month start (e.g., '2', '3'...).
        // Valid first digits are '0' or '1'.
        if (int.parse(limitedDigits[0]) > 1) {
          return oldValue; // Revert to old value if the first digit is invalid
        }
      } else if (limitedDigits.length >= 2) {
        final monthStr = limitedDigits.substring(0, 2);
        final month = int.tryParse(monthStr);

        // Check for invalid month (00 or > 12)
        if (month == null || month == 0 || month > 12) {
          return oldValue; // If the month part is invalid, revert to oldValue
        }
      }
    }
    // End of Month Validation

    String formattedText = limitedDigits;

    // 3. Apply MM/YY formatting
    if (limitedDigits.length >= 2) {
      formattedText = limitedDigits.substring(0, 2); // Month part
      if (limitedDigits.length > 2) {
        formattedText += '/${limitedDigits.substring(2)}'; // Year part with slash
      } else { // Exactly 2 digits, add slash for MM/
        formattedText += '/';
      }
    }

    // 4. Adjust cursor position
    // Calculate how many digits are before the cursor in the original (unformatted) newValue.text
    int digitsBeforeOriginalCursor = 0;
    for (int i = 0; i < newValue.selection.end; i++) {
      if (newValue.text[i].contains(RegExp(r'\d'))) {
        digitsBeforeOriginalCursor++;
      }
    }

    // Map this digits-only cursor position to the formatted text.
    int newSelectionOffset = digitsBeforeOriginalCursor;
    if (digitsBeforeOriginalCursor > 2) {
      newSelectionOffset = digitsBeforeOriginalCursor + 1; // +1 for the slash
    } else if (digitsBeforeOriginalCursor == 2 && formattedText.length > 2 && formattedText[2] == '/') {
      // If cursor is exactly after 2 digits, and a slash was just inserted at index 2
      newSelectionOffset = 3; // Position after MM/
    }


    // Ensure selection index does not go out of bounds
    if (newSelectionOffset > formattedText.length) {
      newSelectionOffset = formattedText.length;
    }
    if (newSelectionOffset < 0) {
      newSelectionOffset = 0;
    }

    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newSelectionOffset),
    );
  }
}