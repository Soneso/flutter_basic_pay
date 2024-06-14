import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinForm extends StatefulWidget {
  final ValueChanged<String> onPinSet;
  final VoidCallback onCancel;
  final String hintText;

  const PinForm({
    required this.onPinSet,
    required this.onCancel,
    this.hintText = "Enter your pin",
    super.key,
  });

  @override
  State<PinForm> createState() => _PinFormState();
}

class _PinFormState extends State<PinForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final pinTextController = TextEditingController();

  @override
  void dispose() {
    pinTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: Theme.of(context).textTheme.bodyMedium,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            obscureText: true,
            validator: (String? value) {
              if (value == null || value.isEmpty || value.length != 6) {
                return 'Please enter 6 digits';
              }
              return null;
            },
            controller: pinTextController,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: () async {
                    // Validate will return true if the form is valid, or false if
                    // the form is invalid.
                    if (_formKey.currentState!.validate()) {
                      widget.onPinSet(pinTextController.text);
                    }
                  },
                  child: const Text(
                    'Submit',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: () async {
                    widget.onCancel();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}