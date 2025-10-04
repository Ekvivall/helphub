import 'dart:async';

import 'package:flutter/material.dart';
import 'package:helphub/core/utils/constants.dart';
import 'package:helphub/data/models/category_chip_model.dart';
import 'package:helphub/routes/app_router.dart';
import 'package:helphub/widgets/custom_date_picker.dart';
import 'package:helphub/widgets/custom_elevated_button.dart';
import 'package:helphub/widgets/custom_text_field.dart';
import 'package:helphub/widgets/custom_time_picker.dart';
import 'package:helphub/widgets/profile/category_chip_widget_with_icon.dart';
import 'package:provider/provider.dart';

import '../../data/models/event_model.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../../validators/auth_validator.dart';
import '../../view_models/event/event_view_model.dart';
import '../../widgets/custom_document_upload_field.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/events/location_coordinates_widget.dart';

class CreateEventScreen extends StatefulWidget {
  final String eventId;

  const CreateEventScreen({super.key, required this.eventId});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  bool _isFormPopulated = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _maxParticipantsController =
      TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedCity = '';
  List<CategoryChipModel> _selectedCategories = [];
  Timer? _geocodingTimer;

  @override
  void initState() {
    super.initState();
    if (widget.eventId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<EventViewModel>(
          context,
          listen: false,
        ).loadEventDetails(widget.eventId);
      });
    }
  }

  @override
  void dispose() {
    _geocodingTimer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    _durationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  // Метод для запуску geocoding з затримкою
  void _triggerGeocoding(String address, String city) {
    _geocodingTimer?.cancel();
    if (address.trim().isEmpty) {
      Provider.of<EventViewModel>(
        context,
        listen: false,
      ).clearEventCoordinates();
      return;
    }

    _geocodingTimer = Timer(const Duration(milliseconds: 1500), () {
      Provider.of<EventViewModel>(
        context,
        listen: false,
      ).geocodeAddress(address.trim(), city);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.eventId.isNotEmpty;
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isEditing ? 'Редагувати подію' : 'Створити подію',
              style: TextStyleHelper.instance.headline24SemiBold.copyWith(
                color: appThemeColors.backgroundLightGrey,
              ),
            ),
          ],
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
        child: Consumer<EventViewModel>(
          builder: (context, viewModel, child) {
            if (widget.eventId.isNotEmpty &&
                viewModel.currentEvent != null &&
                !_isFormPopulated) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _populateFormFields(viewModel.currentEvent!);
                  _isFormPopulated = true;
                }
              });
            }
            if (viewModel.isLoading && viewModel.currentEvent == null) {
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
                      label: 'Назва події',
                      hintText: 'Введіть назву події',
                      labelColor: appThemeColors.backgroundLightGrey,
                      inputType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Будь ласка, введіть назву події';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Опис події',
                      hintText: 'Детальний опис події',
                      labelColor: appThemeColors.backgroundLightGrey,
                      inputType: TextInputType.text,
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Будь ласка, введіть опис події';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomImageUploadField(
                      labelText: 'Фото збору',
                      onChanged: (file) {
                        viewModel.setPickedImageFile(file);
                      },
                      validator: (file) {
                        if (file == null &&
                            viewModel.currentEvent?.photoUrl == null) {
                          return 'Будь ласка, завантажте фото.';
                        }
                        return null;
                      },
                      initialImageUrl: isEditing
                          ? viewModel.currentEvent?.photoUrl
                          : null,
                    ),
                    if (viewModel.user!.city == null) ...[
                      const SizedBox(height: 16),
                      CustomDropdown(
                        labelText: 'Місто',
                        value: viewModel.currentEvent?.city,
                        hintText: 'Оберіть місто',
                        items: Constants.cities.map((String item) {
                          return DropdownItem(key: item, value: item);
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCity = newValue;
                            });
                            if (_locationController.text.isNotEmpty) {
                              _triggerGeocoding(
                                _locationController.text,
                                newValue,
                              );
                            }
                          }
                        },
                        menuMaxHeight: 200,
                        validator: AuthValidator.validateSelectedCity,
                        labelTextStyle: TextStyleHelper.instance.title16Bold
                            .copyWith(
                              height: 1.2,
                              color: appThemeColors.backgroundLightGrey,
                            ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _locationController,
                      label: 'Місце проведення',
                      hintText: 'Адреса або місце зустрічі',
                      labelColor: appThemeColors.backgroundLightGrey,
                      inputType: TextInputType.text,
                      onChanged: (value) {
                        final city = viewModel.user!.city ?? _selectedCity;
                        _triggerGeocoding(value, city);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Будь ласка, введіть місце проведення';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (viewModel.eventCoordinates != null)
                      LocationCoordinatesWidget(
                        coordinates: viewModel.eventCoordinates,
                        errorMessage: viewModel.geocodingError,
                        isLoading: viewModel.isGeocodingLoading,
                        onCoordinatesChanged: (lat, lng) {
                          viewModel.setEventCoordinates(lat, lng);
                        },
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Дата',
                      style: TextStyleHelper.instance.title16Bold.copyWith(
                        color: appThemeColors.backgroundLightGrey,
                      ),
                    ),
                    SizedBox(height: 8),
                    CustomDatePicker(
                      key: ValueKey(_selectedDate),
                      firstDate: viewModel.currentEvent?.date ?? DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                      date: _selectedDate,
                      onDateChanged: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Час',
                      style: TextStyleHelper.instance.title16Bold.copyWith(
                        color: appThemeColors.backgroundLightGrey,
                      ),
                    ),
                    SizedBox(height: 8),
                    CustomTimePicker(
                      key: _selectedTime != null ? ValueKey(_selectedTime) : null,
                      time: _selectedTime,
                      onTimeChanged: (time) {
                        setState(() {
                          _selectedTime = time;
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
                    Consumer<EventViewModel>(
                      builder: (context, viewModel, child) {
                        if (viewModel.isLoading &&
                            viewModel.availableCategories.isEmpty) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: appThemeColors.backgroundLightGrey,
                            ),
                          );
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: viewModel.availableCategories.map((
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
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _maxParticipantsController,
                      label: 'Максимальна кількість учасників',
                      hintText: 'Кількість людей',
                      labelColor: appThemeColors.backgroundLightGrey,
                      inputType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Будь ласка, введіть кількість учасників';
                        }
                        if (value.isNotEmpty) {
                          if (int.tryParse(value) == null) {
                            return 'Будь ласка, введіть коректне число';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _durationController,
                      label: 'Тривалість (наприклад, "2 години 30 хвилин")',
                      hintText: 'Опишіть тривалість',
                      labelColor: appThemeColors.backgroundLightGrey,
                      inputType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Будь ласка, введіть тривалість';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    Consumer<EventViewModel>(
                      builder: (context, viewModel, child) {
                        return CustomElevatedButton(
                          isLoading: viewModel.isLoading,
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              if (viewModel.eventCoordinates == null &&
                                  viewModel.geocodingError != null) {
                                final shouldContinue = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Координати не знайдено'),
                                    content: Text(
                                      'Не вдалося автоматично визначити координати для цієї адреси. '
                                      'Подія буде створена без точних координат. Продовжити?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: Text('Скасувати'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: Text('Продовжити'),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldContinue != true) return;
                              }
                              DateTime eventDateTime = DateTime(
                                _selectedDate!.year,
                                _selectedDate!.month,
                                _selectedDate!.day,
                                _selectedTime!.hour,
                                _selectedTime!.minute,
                              );

                              String? errorMessage;
                              final bool isEditing = widget.eventId.isNotEmpty;

                              if (isEditing) {
                                errorMessage = await viewModel.updateEvent(
                                  eventId: widget.eventId,
                                  title: _titleController.text,
                                  description: _descriptionController.text,
                                  location: _locationController.text,
                                  date: eventDateTime,
                                  categories: _selectedCategories,
                                  maxParticipants: int.tryParse(
                                    _maxParticipantsController.text,
                                  )!,
                                  duration: _durationController.text,
                                  city: viewModel.user!.city ?? _selectedCity,
                                );
                              } else {
                                errorMessage = await viewModel.createEvent(
                                  title: _titleController.text,
                                  description: _descriptionController.text,
                                  location: _locationController.text,
                                  date: eventDateTime,
                                  categories: _selectedCategories,
                                  maxParticipants: int.tryParse(
                                    _maxParticipantsController.text,
                                  )!,
                                  duration: _durationController.text,
                                  city: viewModel.user!.city ?? _selectedCity,
                                );
                              }

                              if (errorMessage == null) {
                                Constants.showSuccessMessage(
                                  context,
                                  isEditing
                                      ? 'Подію "${_titleController.text}" успішно оновлено!'
                                      : 'Подію "${_titleController.text}" успішно створено!',
                                );
                                Navigator.of(context).pushReplacementNamed(
                                  AppRoutes.eventListScreen,
                                );
                              } else {
                                Constants.showErrorMessage(
                                  context,
                                  errorMessage,
                                );
                              }
                            }
                          },
                          text: isEditing ? 'Зберегти зміни' : 'Створити подію',
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

  void _populateFormFields(EventModel event) {
    _titleController.text = event.name;
    _descriptionController.text = event.description;
    _locationController.text = event.locationText;
    _maxParticipantsController.text = event.maxParticipants.toString();
    _durationController.text = event.duration;

    setState(() {
      _selectedDate = event.date;
      _selectedTime = TimeOfDay.fromDateTime(event.date);
      _selectedCategories = List.from(event.categories);
      _selectedCity = event.city;
    });

    final viewModel = Provider.of<EventViewModel>(context, listen: false);
    if (event.locationGeoPoint != null) {
      viewModel.setEventCoordinates(
        event.locationGeoPoint!.latitude,
        event.locationGeoPoint!.longitude,
      );
    }
  }
}
