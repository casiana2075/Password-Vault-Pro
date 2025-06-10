import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard and TextInputFormatter
import 'package:projects/Model/credit_card.dart';
import 'package:projects/services/api_service.dart';
import 'package:projects/utils/authenticateUserBiometrically.dart'; // Assuming this utility exists

class EditCreditCardPage extends StatefulWidget {
  final CreditCard creditCard;

  const EditCreditCardPage({super.key, required this.creditCard});

  @override
  _EditCreditCardPageState createState() => _EditCreditCardPageState();
}

class _EditCreditCardPageState extends State<EditCreditCardPage> {
  late TextEditingController _cardHolderNameController;
  late TextEditingController _cardNumberController;
  late TextEditingController _expiryDateController;
  late TextEditingController _cvvController;
  late TextEditingController _notesController;
  // Removed _typeController as it will be replaced by _selectedCardType

  bool _isLoading = false;
  bool _showFullCardNumber = false;
  bool _showCvv = false;
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
    _cardHolderNameController = TextEditingController(text: widget.creditCard.cardHolderName);
    _cardNumberController = TextEditingController(text: widget.creditCard.cardNumber);
    _expiryDateController = TextEditingController(text: widget.creditCard.expiryDate);
    _cvvController = TextEditingController(text: widget.creditCard.cvv);
    _notesController = TextEditingController(text: widget.creditCard.notes);
    _selectedCardType = widget.creditCard.type; // Initialize selected card type
  }

  @override
  void dispose() {
    _cardHolderNameController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateCreditCard() async {
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
      final updatedCard = await ApiService.updateCreditCard(
        id: widget.creditCard.id,
        cardHolderName: _cardHolderNameController.text,
        cardNumber: _cardNumberController.text.replaceAll(' ', ''), // Remove spaces before sending
        expiryDate: _expiryDateController.text,
        cvv: _cvvController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        type: _selectedCardType, // Use the selected card type from dropdown
      );

      if (updatedCard != null) {
        if (mounted) {
          Navigator.of(context).pop(true); // Indicate success and pop
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Credit Card updated successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update credit card.')),
          );
        }
      }
    } catch (e) {
      print('Error updating credit card: $e');
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

  Future<void> _deleteCreditCard() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this credit card?'),
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

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ApiService.deleteCreditCard(widget.creditCard.id);
      if (success) {
        if (mounted) {
          Navigator.of(context).pop(true); // Indicate success and pop
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Credit Card deleted successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete credit card.')),
          );
        }
      }
    } catch (e) {
      print('Error deleting credit card: $e');
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

  Future<void> _toggleCardNumberVisibility() async {
    if (_showFullCardNumber) {
      setState(() {
        _showFullCardNumber = false;
      });
      return;
    }

    bool authenticated = await authenticateUserBiometrically();
    if (authenticated) {
      setState(() {
        _showFullCardNumber = true;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication failed.')),
        );
      }
    }
  }

  Future<void> _toggleCvvVisibility() async {
    if (_showCvv) {
      setState(() {
        _showCvv = false;
      });
      return;
    }

    bool authenticated = await authenticateUserBiometrically();
    if (authenticated) {
      setState(() {
        _showCvv = true;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication failed.')),
        );
      }
    }
  }

  void _copyCardNumber(BuildContext context) async {
    if (_cardNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Card Number is empty, nothing to copy."),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: _cardNumberController.text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Card Number copied to clipboard"),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
    Future.delayed(const Duration(seconds: 30), () async {
      final currentClipboard = await Clipboard.getData('text/plain');
      if (currentClipboard?.text == _cardNumberController.text) {
        await Clipboard.setData(const ClipboardData(text: ""));
      }
    });
  }

  void _copyCvv(BuildContext context) async {
    if (_cvvController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("CVV is empty, nothing to copy."),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: _cvvController.text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("CVV copied to clipboard"),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
    Future.delayed(const Duration(seconds: 30), () async {
      final currentClipboard = await Clipboard.getData('text/plain');
      if (currentClipboard?.text == _cvvController.text) {
        await Clipboard.setData(const ClipboardData(text: ""));
      }
    });
  }

  // Helper widget for consistent text field styling - MODIFIED TO USE HINTTEXT
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText, // Changed from labelText to hintText
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    int? maxLength,
    int maxLines = 1,
    Widget? suffixIcon, // Added suffixIcon parameter
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
          hintText: hintText, // Use hintText instead of labelText
          hintStyle: const TextStyle( // Add hintStyle for consistent styling
              color: Color.fromARGB(255, 82, 101, 120), fontWeight: FontWeight.w500),
          fillColor: const Color.fromARGB(247, 232, 235, 237),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(35),
          ),
          suffixIcon: suffixIcon, // Use the provided suffixIcon
        ),
        style: const TextStyle(),
      ),
    );
  }

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
    String cardNumberHintText = _selectedCardType != null
        ? 'Card Number (e.g., ${'X' * (_cardTypeLengths[_selectedCardType] ?? 16)})'
        : 'Card Number';

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 10,
          right: 10,
          top: 10,
        ),
        child: SingleChildScrollView(
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
                  "Edit Credit Card",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                ),
              ),
              const SizedBox(height: 20),

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
                    hintText: 'Select Card Type', // Changed to hintText
                    hintStyle: const TextStyle( // Added hintStyle
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
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),

              _buildFormHeading("Card Holder Name"),
              _buildTextField(
                controller: _cardHolderNameController,
                hintText: 'Card Holder Name', // Changed from labelText to hintText
                icon: Icons.person,
                maxLength: 50,
              ),
              const SizedBox(height: 10),

              _buildFormHeading("Card Number"),
              _buildTextField(
                controller: _cardNumberController,
                hintText: cardNumberHintText, // Changed from labelText to hintText (dynamic)
                icon: Icons.credit_card,
                keyboardType: TextInputType.number,
                obscureText: !_showFullCardNumber,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(cardNumberDigitsMaxLength),
                  _CardNumberInputFormatter(),
                ],
                suffixIcon: IconButton(
                  icon: Icon(
                    _showFullCardNumber ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: _toggleCardNumberVisibility,
                ),
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
                          hintText: 'MM/YY', // Changed from labelText to hintText
                          icon: Icons.date_range,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
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
                          hintText: 'CVV', // Changed from labelText to hintText
                          icon: Icons.vpn_key,
                          keyboardType: TextInputType.number,
                          obscureText: !_showCvv,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          maxLength: 3,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showCvv ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: _toggleCvvVisibility,
                          ),
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
                hintText: 'Notes (Optional)', // Changed from labelText to hintText
                icon: Icons.note,
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: 30),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.055,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateCreditCard,
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
                            'Update Card',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.055,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _deleteCreditCard,
                          style: ButtonStyle(
                            elevation: const WidgetStatePropertyAll(5),
                            shadowColor: const WidgetStatePropertyAll(Color.fromARGB(255, 255, 87, 87)),
                            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(35),
                                side: const BorderSide(color: Color.fromARGB(255, 255, 87, 87)),
                              ),
                            ),
                            backgroundColor: const WidgetStatePropertyAll(Color.fromARGB(255, 255, 87, 87)),
                          ),
                          child: const Text(
                            'Delete Card',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: OutlinedButton.icon(
                        onPressed: () => _copyCardNumber(context),
                        icon: const Icon(Icons.copy, color: Colors.grey),
                        label: const Text('Copy Number', style: TextStyle(color: Colors.grey)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(35),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: OutlinedButton.icon(
                        onPressed: () => _copyCvv(context),
                        icon: const Icon(Icons.copy, color: Colors.grey),
                        label: const Text('Copy CVV', style: TextStyle(color: Colors.grey)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(35),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
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