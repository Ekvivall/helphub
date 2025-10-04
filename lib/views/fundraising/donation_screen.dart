import 'package:flutter/material.dart';
import 'package:helphub/core/utils/image_constant.dart';
import 'package:helphub/view_models/donation/donation_view_model.dart';
import 'package:helphub/view_models/profile/profile_view_model.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

import '../../core/utils/constants.dart';
import '../../data/models/fundraising_model.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_field.dart';

class DonationScreen extends StatefulWidget {
  final FundraisingModel fundraising;

  const DonationScreen({super.key, required this.fundraising});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  String? _selectedBank; // 'privat' or 'mono'
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _cardController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  bool _isAnonymous = false;

  final _cardFormatter = MaskTextInputFormatter(
    mask: '#### #### #### ####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _expiryFormatter = MaskTextInputFormatter(
    mask: '##/##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _cvcFormatter = MaskTextInputFormatter(
    mask: '###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    // Вибираємо банк за замовчуванням, якщо він один
    if (widget.fundraising.privatBankCard?.isNotEmpty == true &&
        widget.fundraising.monoBankCard?.isEmpty == true) {
      _selectedBank = 'privat';
    } else if (widget.fundraising.privatBankCard?.isEmpty == true &&
        widget.fundraising.monoBankCard?.isNotEmpty == true) {
      _selectedBank = 'mono';
    }
  }

  @override
  Widget build(BuildContext context) {
    final donationViewModel = Provider.of<DonationViewModel>(context);
    final profileViewModel = Provider.of<ProfileViewModel>(
      context,
      listen: false,
    );
    final fundraising = widget.fundraising;
    final bool hasPrivat = fundraising.privatBankCard?.isNotEmpty ?? false;
    final hasMono = fundraising.monoBankCard?.isNotEmpty ?? false;

    return Scaffold(
      backgroundColor: appThemeColors.blueAccent,
      appBar: AppBar(
        backgroundColor: appThemeColors.appBarBg,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(
            Icons.arrow_back,
            size: 40,
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
        title: Text(
          'Внести донат',
          style: TextStyleHelper.instance.headline24SemiBold.copyWith(
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.9, -0.4),
            end: Alignment(-0.9, 0.4),
            colors: [appThemeColors.blueAccent, appThemeColors.cyanAccent],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fundraising.title ?? '',
                  style: TextStyleHelper.instance.title18Bold.copyWith(
                    color: appThemeColors.backgroundLightGrey,
                  ),
                ),
                const SizedBox(height: 20),

                // секція вибору банку
                if (hasPrivat && hasMono) ...[
                  Text(
                    'Оберіть банк для переказу:',
                    style: TextStyleHelper.instance.title16Bold.copyWith(
                      color: appThemeColors.backgroundLightGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBankChoiceChip(
                          'privat',
                          'PrivatBank',
                          ImageConstant.privatLogo,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildBankChoiceChip(
                          'mono',
                          'Monobank',
                          ImageConstant.monoLogo,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                ],
                CustomTextField(
                  controller: _amountController,
                  label: 'Сума донату (грн)',
                  hintText: 'Введіть суму',
                  labelColor: appThemeColors.backgroundLightGrey,
                  inputType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введіть суму';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Сума має бути більше 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _cardController,
                  label: 'Номер вашої картки',
                  hintText: 'Введіть номер вашої картки',
                  labelColor: appThemeColors.backgroundLightGrey,
                  inputFormatters: [_cardFormatter],
                  inputType: TextInputType.number,
                  validator: (value) {
                    final cleanValue = value?.replaceAll(' ', '');
                    if (cleanValue == null || cleanValue.length != 16) {
                      return 'Некоректний номер картки';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _expiryController,
                        label: 'Термін дії (ММ/РР)',
                        hintText: 'Введіть термін дії',
                        labelColor: appThemeColors.backgroundLightGrey,
                        inputFormatters: [_expiryFormatter],
                        inputType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.length != 5) {
                            return 'Введіть ММ/РР';
                          }
                          final parts = value.split('/');
                          final month = int.tryParse(parts[0]);
                          final year = int.tryParse(parts[1]);
                          if (month == null ||
                              year == null ||
                              month < 1 ||
                              month > 12) {
                            return 'Некоректна дата';
                          }
                          final currentYear = DateTime.now().year % 100;
                          if (year < currentYear ||
                              (year == currentYear &&
                                  month < DateTime.now().month)) {
                            return 'Термін дії минув';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _cvcController,
                        label: 'Термін CVC',
                        hintText: 'Введіть CVC',
                        labelColor: appThemeColors.backgroundLightGrey,
                        inputFormatters: [_cvcFormatter],
                        inputType: TextInputType.number,
                        validator: (value) =>
                            (value?.length ?? 0) < 3 ? 'Введіть 3 цифри' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Зробити донат анонімно',
                      style: TextStyleHelper.instance.title16Bold.copyWith(
                        color: appThemeColors.backgroundLightGrey,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _isAnonymous,
                      onChanged: (value) {
                        setState(() {
                          _isAnonymous = value;
                        });
                      },
                      activeColor: appThemeColors.backgroundLightGrey,
                      inactiveTrackColor: appThemeColors.backgroundLightGrey,
                      inactiveThumbColor: appThemeColors.appBarBg,
                      trackOutlineColor: WidgetStateProperty.all(
                        Colors.transparent,
                      ),
                    ),
                  ],
                ),
                // Додано перевірку та повідомлення
                if (widget.fundraising.hasRaffle && _isAnonymous)
                  _buildAnonymousDisclaimer(),
                const SizedBox(height: 24),
                CustomElevatedButton(
                  isLoading: donationViewModel.isLoading,
                  text: 'Задонатити',
                  onPressed: () async {
                    if (_selectedBank == null && (hasPrivat && hasMono)) {
                      Constants.showErrorMessage(
                        context,
                        'Будь ласка, оберіть банк',
                      );
                      return;
                    }
                    if (_formKey.currentState!.validate()) {
                      final success = await donationViewModel.makeDonation(
                        amount: double.parse(_amountController.text),
                        fundraisingId: widget.fundraising.id!,
                        donor: profileViewModel.user!,
                        isAnonymous: _isAnonymous,
                        fundraising: fundraising,
                      );

                      if (success && mounted) {
                        Navigator.of(context).pop();
                        Constants.showSuccessMessage(
                          context,
                          'Дякуємо! Ваш донат надіслано.',
                        );
                      } else if (mounted &&
                          donationViewModel.errorMessage != null) {
                        Constants.showErrorMessage(
                          context,
                          donationViewModel.errorMessage!,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnonymousDisclaimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: appThemeColors.errorRed.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: appThemeColors.errorRed.withAlpha(178)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: appThemeColors.errorRed.withAlpha(178),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Зверніть увагу: Анонімні донати не беруть участі у розіграші. Якщо ви хочете взяти участь, будь ласка, зніміть галочку "Анонімний донат".',
                style: TextStyleHelper.instance.title13Regular.copyWith(
                  color: appThemeColors.primaryWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankChoiceChip(
    String bankKey,
    String bankName,
    String logoAsset,
  ) {
    final isSelected = _selectedBank == bankKey;
    return ChoiceChip(
      label: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(logoAsset, height: 20),
          const SizedBox(width: 8),
          Text(bankName),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) _selectedBank = bankKey;
        });
      },
      selectedColor: appThemeColors.blueAccent.withAlpha(78),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? appThemeColors.blueAccent : Colors.grey,
        ),
      ),
    );
  }
}
