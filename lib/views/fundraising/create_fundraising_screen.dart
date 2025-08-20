import 'package:flutter/material.dart';
import 'package:helphub/models/category_chip_model.dart';
import 'package:helphub/models/fundraiser_application_model.dart';
import 'package:helphub/widgets/custom_document_upload_field.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

import '../../core/utils/constants.dart';
import '../../models/fundraising_model.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../../view_models/fundraiser_application/fundraiser_application_view_model.dart';
import '../../view_models/fundraising/fundraising_view_model.dart';
import '../../widgets/custom_date_picker.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_multi_document_upload_field.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/profile/category_chip_widget_with_icon.dart';

class CreateFundraisingScreen extends StatefulWidget {
  final String fundraisingId;

  const CreateFundraisingScreen({super.key, required this.fundraisingId});

  @override
  State<CreateFundraisingScreen> createState() =>
      _CreateFundraisingScreenState();
}

class _CreateFundraisingScreenState extends State<CreateFundraisingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();
  final TextEditingController _privatBankCardController =
      TextEditingController();
  final TextEditingController _monoBankCardController = TextEditingController();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  List<CategoryChipModel> _selectedCategories = [];
  final List<FundraiserApplicationModel> _selectedApplications = [];
  bool _isUrgent = false;
  bool _showApplicationsSection = false;

  final _cardNumberFormatter = MaskTextInputFormatter(
    mask: '#### #### #### ####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool hasRaffle = false;
  final TextEditingController ticketPriceController = TextEditingController();
  final TextEditingController prizesController = TextEditingController();
  bool _isFormPopulated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fundraisingViewModel = Provider.of<FundraisingViewModel>(
        context,
        listen: false,
      );
      final applicationViewModel = Provider.of<FundraiserApplicationViewModel>(
        context,
        listen: false,
      );
      applicationViewModel.loadApprovedApplicationsForOrganization(
        fundraisingViewModel.currentAuthUserId!,
      );
      if (widget.fundraisingId.isNotEmpty) {
        fundraisingViewModel.loadFundraisingDetails(widget.fundraisingId);
      }
    });
  }

  void _populateFormFields(FundraisingModel fundraising) {
    _titleController.text = fundraising.title ?? '';
    _descriptionController.text = fundraising.description ?? '';
    _targetAmountController.text =
        fundraising.targetAmount?.toStringAsFixed(0) ?? '';
    _privatBankCardController.text = fundraising.privatBankCard ?? '';
    _monoBankCardController.text = fundraising.monoBankCard ?? '';

    setState(() {
      _selectedStartDate = fundraising.startDate;
      _selectedEndDate = fundraising.endDate;
      _selectedCategories = List.from(fundraising.categories ?? []);
      _isUrgent = fundraising.isUrgent ?? false;
      hasRaffle = fundraising.hasRaffle;
      ticketPriceController.text =
          fundraising.ticketPrice?.toStringAsFixed(0) ?? '';
      prizesController.text = fundraising.prizes?.join(';') ?? '';
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    _privatBankCardController.dispose();
    _monoBankCardController.dispose();
    ticketPriceController.dispose();
    prizesController.dispose();
    super.dispose();
  }

  void _updateTotalAmountFromApplications() {
    if (_selectedApplications.isNotEmpty) {
      final totalAmount = _selectedApplications.fold<double>(
        0,
        (sum, app) => sum + app.requiredAmount,
      );
      _targetAmountController.text = totalAmount.toStringAsFixed(2);
    }
  }

  void _populateFieldsFromApplications() {
    if (_selectedApplications.isEmpty) return;

    final Set<CategoryChipModel> allCategories = {};
    final Set<String> categoryTitles = {};

    for (var app in _selectedApplications) {
      for (var category in app.categories) {
        if (!categoryTitles.contains(category.title)) {
          allCategories.add(category);
          categoryTitles.add(category.title!);
        }
      }
    }

    setState(() {
      _selectedCategories.clear();
      _selectedCategories.addAll(allCategories);
    });

    if (_titleController.text.isEmpty) {
      if (_selectedApplications.length == 1) {
        _titleController.text = _selectedApplications.first.title;
      } else {
        _titleController.text =
            'Комбінований збір з ${_selectedApplications.length} заявок';
      }
    }

    if (_descriptionController.text.isEmpty) {
      final descriptions = _selectedApplications
          .map((app) => '• ${app.title}: ${app.description}')
          .join('\n\n');
      _descriptionController.text = descriptions;
    }

    _updateTotalAmountFromApplications();
    if (_selectedEndDate == null) {
      if (_selectedApplications.isNotEmpty) {
        DateTime? latestDate;
        for (var app in _selectedApplications) {
          final appDate = app.deadline.toDate();
          if (latestDate == null || appDate.isAfter(latestDate)) {
            latestDate = appDate;
          }
        }
        setState(() {
          _selectedEndDate = latestDate;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.fundraisingId.isNotEmpty;
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
          isEditing ? 'Редагувати збір' : 'Створити збір',
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
        child: Consumer2<FundraisingViewModel, FundraiserApplicationViewModel>(
          builder: (context, fundraisingViewModel, applicationViewModel, child) {
            final isEditing = widget.fundraisingId.isNotEmpty;
            if (isEditing &&
                fundraisingViewModel.currentFundraising != null &&
                !_isFormPopulated) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _populateFormFields(fundraisingViewModel.currentFundraising!);
                  _isFormPopulated = true;
                }
              });
            }
            if (fundraisingViewModel.isLoading &&
                fundraisingViewModel.user == null) {
              return Center(
                child: CircularProgressIndicator(
                  color: appThemeColors.blueAccent,
                ),
              );
            }

            if (fundraisingViewModel.errorMessage != null) {
              return Center(
                child: Text(
                  fundraisingViewModel.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyleHelper.instance.title16Regular.copyWith(
                    color: appThemeColors.blueMixedColor,
                  ),
                ),
              );
            }

            final approvedApplications =
                applicationViewModel.approvedApplications;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Секція вибору заявок
                    if (approvedApplications.isNotEmpty && !isEditing) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: appThemeColors.primaryWhite.withAlpha(14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: appThemeColors.backgroundLightGrey.withAlpha(
                              77,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Заявки на фінансування',
                                  style: TextStyleHelper.instance.title16Bold
                                      .copyWith(
                                        color:
                                            appThemeColors.backgroundLightGrey,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: appThemeColors.backgroundLightGrey,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${approvedApplications.length}',
                                    style: TextStyleHelper
                                        .instance
                                        .title13Regular
                                        .copyWith(
                                          color: appThemeColors.blueAccent,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _showApplicationsSection =
                                          !_showApplicationsSection;
                                    });
                                  },
                                  icon: Icon(
                                    _showApplicationsSection
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: appThemeColors.backgroundLightGrey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Оберіть заявки, які покриватиме цей збір (необов\'язково)',
                              style: TextStyleHelper.instance.title14Regular
                                  .copyWith(
                                    color: appThemeColors.backgroundLightGrey
                                        .withAlpha(177),
                                  ),
                            ),
                            if (_showApplicationsSection) ...[
                              const SizedBox(height: 12),
                              ...approvedApplications.map((application) {
                                final isSelected = _selectedApplications.any(
                                  (selected) => selected.id == application.id,
                                );

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? appThemeColors.backgroundLightGrey
                                              .withAlpha(14)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? appThemeColors.backgroundLightGrey
                                          : appThemeColors.backgroundLightGrey
                                                .withAlpha(77),
                                    ),
                                  ),
                                  child: CheckboxListTile(
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedApplications.add(
                                            application,
                                          );
                                        } else {
                                          _selectedApplications.removeWhere(
                                            (selected) =>
                                                selected.id == application.id,
                                          );
                                        }
                                        _populateFieldsFromApplications();
                                      });
                                    },
                                    title: Text(
                                      application.title,
                                      style: TextStyleHelper
                                          .instance
                                          .title14Regular
                                          .copyWith(
                                            color: appThemeColors
                                                .backgroundLightGrey,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          application.description.length > 100
                                              ? '${application.description.substring(0, 100)}...'
                                              : application.description,
                                          style: TextStyleHelper
                                              .instance
                                              .title13Regular
                                              .copyWith(
                                                color: appThemeColors
                                                    .backgroundLightGrey
                                                    .withAlpha(177),
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${application.requiredAmount.toStringAsFixed(0)} грн',
                                          style: TextStyleHelper
                                              .instance
                                              .title14Regular
                                              .copyWith(
                                                color: appThemeColors
                                                    .backgroundLightGrey,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                    checkColor: appThemeColors.blueAccent,
                                    activeColor:
                                        appThemeColors.backgroundLightGrey,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  ),
                                );
                              }),
                              if (_selectedApplications.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: appThemeColors.backgroundLightGrey
                                        .withAlpha(14),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color:
                                            appThemeColors.backgroundLightGrey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Обрано ${_selectedApplications.length} заявок на загальну суму ${_selectedApplications.fold<double>(0, (sum, app) => sum + app.requiredAmount).toStringAsFixed(0)} грн',
                                          style: TextStyleHelper
                                              .instance
                                              .title13Regular
                                              .copyWith(
                                                color: appThemeColors
                                                    .backgroundLightGrey,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Основні поля форми
                    CustomTextField(
                      controller: _titleController,
                      label: 'Назва збору',
                      hintText: 'Введіть назву збору коштів',
                      labelColor: appThemeColors.backgroundLightGrey,
                      inputType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Будь ласка, введіть назву збору';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Детальний опис',
                      hintText:
                          'Опишіть мету збору, як будуть використані кошти...',
                      labelColor: appThemeColors.backgroundLightGrey,
                      inputType: TextInputType.text,
                      maxLines: 6,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Будь ласка, введіть опис збору';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _targetAmountController,
                      label: 'Цільова сума (грн)',
                      hintText: '0.00',
                      labelColor: appThemeColors.backgroundLightGrey,
                      inputType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Будь ласка, введіть цільову суму';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Введіть коректну суму більше 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Період збору',
                      style: TextStyleHelper.instance.title16Bold.copyWith(
                        color: appThemeColors.backgroundLightGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Початкова дата',
                      style: TextStyleHelper.instance.title14Regular.copyWith(
                        color: appThemeColors.backgroundLightGrey,
                      ),
                    ),
                    CustomDatePicker(
                      key: _selectedStartDate != null
                          ? ValueKey(_selectedStartDate)
                          : null,
                      firstDate:
                          fundraisingViewModel.currentFundraising?.startDate ??
                          DateTime.now(),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 2),
                      ),
                      onDateChanged: (date) {
                        setState(() {
                          _selectedStartDate = date;
                        });
                      },
                      date: _selectedStartDate,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Кінцева дата',
                      style: TextStyleHelper.instance.title14Regular.copyWith(
                        color: appThemeColors.backgroundLightGrey,
                      ),
                    ),
                    CustomDatePicker(
                      key: _selectedEndDate != null
                          ? ValueKey(_selectedEndDate)
                          : null,
                      firstDate: _selectedStartDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 2),
                      ),
                      onDateChanged: (date) {
                        setState(() {
                          _selectedEndDate = date;
                        });
                      },
                      date: _selectedEndDate,
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
                      children: fundraisingViewModel.availableCategories.map((
                        category,
                      ) {
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
                      controller: _privatBankCardController,
                      label: 'Картка PrivatBank (необов\'язково)',
                      hintText: '0000 0000 0000 0000',
                      labelColor: appThemeColors.backgroundLightGrey,
                      inputType: TextInputType.number,
                      inputFormatters: [_cardNumberFormatter],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null;
                        }

                        final cleanCardNumber = _cardNumberFormatter.unmaskText(
                          value,
                        );

                        if (cleanCardNumber.length != 16) {
                          return 'Некоректний номер картки';
                        }

                        return null;
                      },
                      isRequired: false,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _monoBankCardController,
                      label: 'Картка Monobank (необов\'язково)',
                      hintText: '0000 0000 0000 0000',
                      labelColor: appThemeColors.backgroundLightGrey,
                      inputType: TextInputType.number,
                      inputFormatters: [_cardNumberFormatter],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null;
                        }

                        final cleanCardNumber = _cardNumberFormatter.unmaskText(
                          value,
                        );

                        if (cleanCardNumber.length != 16) {
                          return 'Некоректний номер картки';
                        }

                        return null;
                      },
                      isRequired: false,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Терміновий збір',
                          style: TextStyleHelper.instance.title16Bold.copyWith(
                            color: appThemeColors.backgroundLightGrey,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _isUrgent,
                          onChanged: (value) {
                            setState(() {
                              _isUrgent = value;
                            });
                          },
                          activeColor: appThemeColors.backgroundLightGrey,
                          inactiveTrackColor:
                              appThemeColors.backgroundLightGrey,
                          inactiveThumbColor: appThemeColors.appBarBg,
                          trackOutlineColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Text(
                          'Додати розіграш',
                          style: TextStyleHelper.instance.title16Bold.copyWith(
                            color: appThemeColors.backgroundLightGrey,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: hasRaffle,
                          onChanged: (value) {
                            setState(() {
                              hasRaffle = value;
                            });
                          },
                          activeColor: appThemeColors.backgroundLightGrey,
                          inactiveTrackColor:
                              appThemeColors.backgroundLightGrey,
                          inactiveThumbColor: appThemeColors.appBarBg,
                          trackOutlineColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                    if (hasRaffle) ...[
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: ticketPriceController,
                        label: 'Вартість квитка (грн)',
                        hintText: 'Введіть вартість квитка',
                        labelColor: appThemeColors.backgroundLightGrey,
                        inputType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Будь ласка, введіть вартість квитка';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Введіть коректну вартість більше 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: prizesController,
                        label: 'Назви призів, розділяючи \';\'',
                        hintText: "Наприклад: Powerbank;Футболка;Термос",
                        labelColor: appThemeColors.backgroundLightGrey,
                        inputType: TextInputType.text,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Будь ласка, введіть хоча б один приз';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    CustomImageUploadField(
                      labelText: 'Фото збору',
                      onChanged: (file) {
                        fundraisingViewModel.setPickedImageFile(file);
                      },
                      validator: (file) {
                        if (file == null &&
                            fundraisingViewModel.currentFundraising?.photoUrl ==
                                null) {
                          return 'Будь ласка, завантажте фото.';
                        }
                        return null;
                      },
                      initialImageUrl: isEditing
                          ? fundraisingViewModel.currentFundraising?.photoUrl
                          : null,
                    ),

                    const SizedBox(height: 16),
                    CustomMultiDocumentUploadField(
                      labelText: 'Документи (необов\'язково)',
                      onChanged: (files) {
                        fundraisingViewModel.setPickedDocuments(files);
                      },
                      initialDocumentUrls:
                          fundraisingViewModel.currentFundraising?.documentUrls,
                    ),

                    const SizedBox(height: 32),
                    Consumer<FundraisingViewModel>(
                      builder: (context, viewModel, child) {
                        return CustomElevatedButton(
                          isLoading:
                              viewModel.isLoading || viewModel.isUploadingFiles,
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              String? errorMessage;
                              if (_selectedStartDate == null ||
                                  _selectedEndDate == null) {
                                errorMessage =
                                    'Будь ласка, оберіть дати початку та кінця збору.';
                              } else if (_selectedEndDate!.isBefore(
                                _selectedStartDate!,
                              )) {
                                errorMessage =
                                    'Дата кінця не може бути раніше дати початку.';
                              } else if (_selectedCategories.isEmpty) {
                                errorMessage =
                                    'Будь ласка, оберіть хоча б одну категорію.';
                              }

                              if (errorMessage != null) {
                                Constants.showErrorMessage(
                                  context,
                                  errorMessage,
                                );
                                return;
                              }

                              final targetAmount = double.tryParse(
                                _targetAmountController.text,
                              );
                              if (targetAmount == null) {
                                Constants.showErrorMessage(
                                  context,
                                  'Некоректна цільова сума',
                                );
                                return;
                              }
                              // Підготовка списку ID обраних заявок
                              final selectedApplicationIds =
                                  _selectedApplications
                                      .map((app) => app.id)
                                      .toList();
                              final isEditing = widget.fundraisingId.isNotEmpty;
                              if (isEditing) {
                                errorMessage = await viewModel
                                    .updateFundraising(
                                      fundraisingId: widget.fundraisingId,
                                      title: _titleController.text.trim(),
                                      description: _descriptionController.text
                                          .trim(),
                                      targetAmount: targetAmount,
                                      categories: _selectedCategories,
                                      startDate: _selectedStartDate!,
                                      endDate: _selectedEndDate!,
                                      privatBankCard: _privatBankCardController
                                          .text
                                          .trim(),
                                      monoBankCard: _monoBankCardController.text
                                          .trim(),
                                      isUrgent: _isUrgent,
                                      hasRaffle: hasRaffle,
                                      ticketPrice: hasRaffle
                                          ? double.tryParse(
                                                  ticketPriceController.text,
                                                ) ??
                                                1
                                          : null,
                                      prizes: hasRaffle
                                          ? prizesController.text
                                                .trim()
                                                .split(';')
                                                .toList()
                                          : null,
                                    );
                              } else {
                                errorMessage = await viewModel
                                    .createFundraising(
                                      title: _titleController.text.trim(),
                                      description: _descriptionController.text
                                          .trim(),
                                      targetAmount: targetAmount,
                                      categories: _selectedCategories,
                                      startDate: _selectedStartDate!,
                                      endDate: _selectedEndDate!,
                                      privatBankCard: _privatBankCardController
                                          .text
                                          .trim(),
                                      monoBankCard: _monoBankCardController.text
                                          .trim(),
                                      isUrgent: _isUrgent,
                                      relatedApplicationIds:
                                          selectedApplicationIds,
                                      hasRaffle: hasRaffle,
                                      ticketPrice: hasRaffle
                                          ? double.tryParse(
                                                  ticketPriceController.text,
                                                ) ??
                                                1
                                          : null,
                                      prizes: hasRaffle
                                          ? prizesController.text
                                                .trim()
                                                .split(';')
                                                .toList()
                                          : null,
                                    );
                              }

                              if (errorMessage == null) {
                                if (_selectedApplications.isNotEmpty) {
                                  for (var application
                                      in _selectedApplications) {
                                    await applicationViewModel
                                        .updateApplicationStatus(
                                          application.id,
                                          FundraisingStatus.active,
                                        );
                                  }
                                }
                                Constants.showSuccessMessage(
                                  context,
                                  'Збір "${_titleController.text}" успішно створено!',
                                );
                                Navigator.of(context).pop();
                              } else {
                                Constants.showErrorMessage(
                                  context,
                                  errorMessage,
                                );
                              }
                            }
                          },
                          text: isEditing ? 'Зберегти зміни' : 'Створити збір',
                          backgroundColor: appThemeColors.blueAccent,
                          textStyle: TextStyleHelper.instance.title16Bold
                              .copyWith(color: appThemeColors.primaryWhite),
                          borderRadius: 10,
                        );
                      },
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
