import 'package:flutter/material.dart';
import 'package:helphub/data/models/category_chip_model.dart';
import 'package:provider/provider.dart';

import '../../core/utils/constants.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../../view_models/fundraiser_application/fundraiser_application_view_model.dart';
import '../../widgets/custom_date_picker.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_multi_document_upload_field.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/profile/category_chip_widget_with_icon.dart';

class CreateFundraisingApplicationScreen extends StatefulWidget {
  final String organizationId; // Якщо передано, то заявка на конкретний фонд

  const CreateFundraisingApplicationScreen({
    super.key,
    required this.organizationId,
  });

  @override
  State<CreateFundraisingApplicationScreen> createState() =>
      _CreateFundraisingApplicationScreenState();
}

class _CreateFundraisingApplicationScreenState
    extends State<CreateFundraisingApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _requiredAmountController =
      TextEditingController();
  final TextEditingController _contactInfoController = TextEditingController();
  DateTime? _selectedDeadline;
  String _selectedOrganizationId = '';
  List<CategoryChipModel> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _selectedOrganizationId = widget.organizationId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _requiredAmountController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Заявка на фінансування',
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
        child: Consumer<FundraiserApplicationViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && viewModel.user == null) {
              return Center(
                child: CircularProgressIndicator(
                  color: appThemeColors.blueAccent,
                ),
              );
            }
            if (viewModel.errorMessage != null) {
              return Center(
                child: Text(
                  viewModel.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyleHelper.instance.title16Regular.copyWith(
                    color: appThemeColors.blueMixedColor,
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _titleController,
                      label: 'Назва запиту',
                      hintText: 'Коротка назва того, на що потрібні кошти',
                      labelColor: appThemeColors.backgroundLightGrey,
                      inputType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Будь ласка, введіть назву запиту';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Детальний опис',
                      hintText:
                          'Опишіть детально, для чого потрібні кошти, як вони будуть використані...',
                      labelColor: appThemeColors.backgroundLightGrey,
                      inputType: TextInputType.text,
                      maxLines: 6,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Будь ласка, введіть опис запиту';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _requiredAmountController,
                      label: 'Необхідна сума (грн)',
                      hintText: '0.00',
                      labelColor: appThemeColors.backgroundLightGrey,
                      inputType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Будь ласка, введіть необхідну суму';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Введіть коректну суму більше 0';
                        }
                        if (amount > 1000000) {
                          return 'Максимальна сума заявки: 1,000,000 грн';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (widget.organizationId.isEmpty) ...[
                      CustomDropdown(
                        labelText: 'Фонд (необов\'язково)',
                        value: _selectedOrganizationId.isEmpty
                            ? null
                            : _selectedOrganizationId,
                        hintText: 'Оберіть фонд для подачі заявки',
                        items: viewModel.availableOrganizations
                            .map(
                              (org) => DropdownItem(
                                key: org.uid!,
                                value: org.organizationName ?? 'Невідомий фонд',
                              ),
                            )
                            .toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedOrganizationId = newValue ?? '';
                          });
                        },
                        labelTextStyle: TextStyleHelper.instance.title16Bold
                            .copyWith(
                              height: 1.2,
                              color: appThemeColors.backgroundLightGrey,
                            ),
                        menuMaxHeight: 200,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Термін',
                      style: TextStyleHelper.instance.title16Bold.copyWith(
                        color: appThemeColors.backgroundLightGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    CustomDatePicker(
                      firstDate: DateTime.now().add(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      onDateChanged: (date) {
                        setState(() {
                          _selectedDeadline = date;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Категорії',
                      style: TextStyleHelper.instance.title16Bold.copyWith(
                        color: appThemeColors.backgroundLightGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: viewModel.availableCategories.map((category) {
                        final bool isSelected = _selectedCategories.any(
                          (selected) => selected.title == category.title,
                        );
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedCategories.remove(category);
                              } else {
                                _selectedCategories.add(category);
                              }
                            });
                          },
                          child: CategoryChipWidgetWithIcon(
                            chip: category,
                            isSelected: isSelected,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _contactInfoController,
                      label: 'Контактна інформація',
                      hintText: 'Email, телефон для зв\'язку',
                      labelColor: appThemeColors.backgroundLightGrey,
                      inputType: TextInputType.text,
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Будь ласка, введіть контактну інформацію';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomMultiDocumentUploadField(
                      labelText: 'Підтверджуючі документи',
                      onChanged: (files) {
                        viewModel.setPickedDocuments(files);
                      },
                    ),
                    const SizedBox(height: 32),
                    CustomElevatedButton(
                      isLoading: viewModel.isLoading,
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          String? errorMessage;
                          if (_selectedDeadline == null) {
                            errorMessage =
                                'Будь ласка, оберіть термін виконання.';
                          } else if (_selectedCategories.isEmpty) {
                            errorMessage =
                                'Будь ласка, оберіть хоча б одну категорію.';
                          }
                          if (errorMessage != null) {
                            Constants.showErrorMessage(context, errorMessage);
                            return;
                          }

                          final requiredAmount = double.tryParse(
                            _requiredAmountController.text,
                          );
                          if (requiredAmount == null) {
                            Constants.showErrorMessage(
                              context,
                              'Некоректна сума',
                            );
                            return;
                          }

                          errorMessage = await viewModel.submitApplication(
                            title: _titleController.text.trim(),
                            description: _descriptionController.text.trim(),
                            requiredAmount: requiredAmount,
                            deadline: _selectedDeadline!,
                            categories: _selectedCategories,
                            organizationId: _selectedOrganizationId,
                            contactInfo: _contactInfoController.text.trim(),
                          );

                          if (errorMessage == null) {
                            Constants.showSuccessMessage(
                              context,
                              'Заявку "${_titleController.text}" успішно подано!',
                            );
                            Navigator.of(context).pop();
                          } else {
                            Constants.showErrorMessage(context, errorMessage);
                          }
                        }
                      },
                      text: 'Подати заявку',
                      backgroundColor: appThemeColors.blueAccent,
                      textStyle: TextStyleHelper.instance.title16Bold.copyWith(
                        color: appThemeColors.primaryWhite,
                      ),
                      borderRadius: 10,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
