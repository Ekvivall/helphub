import 'dart:async';

import 'package:flutter/material.dart';
import 'package:helphub/models/category_chip_model.dart';
import 'package:helphub/models/project_task_model.dart';
import 'package:provider/provider.dart';

import '../../core/utils/constants.dart';
import '../../models/project_model.dart';
import '../../routes/app_router.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../../validators/auth_validator.dart';
import '../../view_models/project/project_view_model.dart';
import '../../widgets/custom_date_picker.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/events/location_coordinates_widget.dart';
import '../../widgets/profile/category_chip_widget_with_icon.dart';

class CreateProjectScreen extends StatefulWidget {
  final String? projectId;

  const CreateProjectScreen({super.key, this.projectId});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String _selectedCity = '';
  List<CategoryChipModel> _selectedCategories = [];
  List<String> _selectedSkills = [];
  List<ProjectTaskModel> _tasks = [];
  bool _isOnlyFriends = false;
  bool _isFormPopulated = false;
  Timer? _geocodingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<ProjectViewModel>(context, listen: false);
      if (widget.projectId != null && widget.projectId!.isNotEmpty) {
        viewModel.loadProjectDetails(widget.projectId!);
      }
      viewModel.fetchSkillsAndCategories();
    });
  }

  @override
  void dispose() {
    _geocodingTimer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _confirmRemoveTask(int index) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Підтвердження видалення'),
          content: const Text('Ви впевнені, що хочете видалити це завдання?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel
              },
              child: const Text('Скасувати'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm
              },
              child: const Text('Видалити'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      _removeTask(index);
    }
  }

  void _triggerGeocoding(String address, String city) {
    _geocodingTimer?.cancel();
    if (address.trim().isEmpty) {
      Provider.of<ProjectViewModel>(
        context,
        listen: false,
      ).clearProjectCoordinates();
      return;
    }

    _geocodingTimer = Timer(const Duration(milliseconds: 1500), () {
      Provider.of<ProjectViewModel>(
        context,
        listen: false,
      ).geocodeAddress(address.trim(), city);
    });
  }

  void _addTask() {
    setState(() {
      _tasks.add(
        ProjectTaskModel(
          title: '',
          description: '',
          neededPeople: 1,
          deadline: null,
        ),
      );
    });
  }

  void _removeTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing =
        widget.projectId != null && widget.projectId!.isNotEmpty;

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
          isEditing ? 'Редагувати проєкт' : 'Створити проєкт',
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
        child: Consumer<ProjectViewModel>(
          builder: (context, viewModel, child) {
            if (isEditing &&
                viewModel.currentProject != null &&
                !_isFormPopulated) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _populateFormFields(viewModel.currentProject!);
                  _isFormPopulated = true;
                }
              });
            }
            if (viewModel.isLoading &&
                viewModel.currentProject == null &&
                isEditing) {
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
                      label: 'Назва проєкту',
                      hintText: 'Введіть назву проєкту',
                      labelColor: appThemeColors.backgroundLightGrey,
                      inputType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Будь ласка, введіть назву проєкту';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Опис проєкту',
                      hintText: 'Детальний опис проєкту',
                      labelColor: appThemeColors.backgroundLightGrey,
                      inputType: TextInputType.text,
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Будь ласка, введіть опис проєкту';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (viewModel.user?.city == null) ...[
                      const SizedBox(height: 16),
                      CustomDropdown(
                        labelText: 'Місто',
                        value: viewModel.currentProject?.city,
                        hintText: 'Оберіть місто',
                        items: Constants.cities,
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
                        final city = viewModel.user?.city ?? _selectedCity;
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
                    if (viewModel.projectCoordinates != null)
                      LocationCoordinatesWidget(
                        coordinates: viewModel.projectCoordinates,
                        errorMessage: viewModel.geocodingError,
                        isLoading: viewModel.isGeocodingLoading,
                        onCoordinatesChanged: (lat, lng) {
                          viewModel.setProjectCoordinates(lat!, lng!);
                        },
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Початкова дата',
                      style: TextStyleHelper.instance.title16Bold.copyWith(
                        color: appThemeColors.backgroundLightGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    CustomDatePicker(
                      firstDate: DateTime.now(),
                      lastDate:
                          _selectedEndDate ??
                          DateTime.now().add(const Duration(days: 365 * 2)),
                      date: viewModel.currentProject?.startDate,
                      onDateChanged: (date) {
                        setState(() {
                          _selectedStartDate = date;
                        });
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Кінцева дата',
                      style: TextStyleHelper.instance.title16Bold.copyWith(
                        color: appThemeColors.backgroundLightGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    CustomDatePicker(
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 2),
                      ),
                      date: viewModel.currentProject?.endDate,
                      onDateChanged: (date) {
                        setState(() {
                          _selectedEndDate = date;
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
                    Text(
                      'Навички',
                      style: TextStyleHelper.instance.title16Bold.copyWith(
                        color: appThemeColors.backgroundLightGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: viewModel.availableSkills.map((skill) {
                        final bool isSelected = _selectedSkills.contains(
                          skill.title,
                        );
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedSkills.remove(skill.title);
                              } else {
                                _selectedSkills.add(skill.title!);
                              }
                            });
                          },
                          child: Chip(
                            padding: const EdgeInsets.all(5),
                            label: Text(skill.title!),
                            backgroundColor: isSelected
                                ? appThemeColors.blueAccent
                                : appThemeColors.textMediumGrey,
                            labelStyle: TextStyleHelper.instance.title14Regular
                                .copyWith(
                                  color: isSelected
                                      ? appThemeColors.primaryWhite
                                      : appThemeColors.textLightColor,
                                ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Завдання',
                      style: TextStyleHelper.instance.title16Bold.copyWith(
                        color: appThemeColors.backgroundLightGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            color: appThemeColors.blueMixedColor,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Завдання #${index + 1}',
                                        style: TextStyleHelper
                                            .instance
                                            .title16Bold
                                            .copyWith(
                                              color:
                                                  appThemeColors.primaryBlack,
                                            ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: appThemeColors.errorRed,
                                        ),
                                        onPressed: () =>
                                            _confirmRemoveTask(index),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  CustomTextField(
                                    label: 'Назва завдання',
                                    initialValue: _tasks[index].title,
                                    onChanged: (value) {
                                      _tasks[index] = _tasks[index].copyWith(
                                        title: value,
                                      );
                                    },
                                    labelColor: appThemeColors.primaryBlack,
                                    hintText: 'Опишіть завдання',
                                    inputType: TextInputType.text,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Введіть назву';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  CustomTextField(
                                    label: 'Опис завдання',
                                    initialValue: _tasks[index].description,
                                    onChanged: (value) {
                                      _tasks[index] = _tasks[index].copyWith(
                                        description: value,
                                      );
                                    },
                                    labelColor: appThemeColors.primaryBlack,
                                    hintText: 'Детальний опис',
                                    maxLines: 3,
                                    inputType: TextInputType.text,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Термін виконання',
                                    style: TextStyleHelper.instance.title16Bold
                                        .copyWith(
                                          color: appThemeColors.primaryBlack,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  CustomDatePicker(
                                    dateLabel: 'Термін виконання',
                                    firstDate: DateTime.now(),
                                    errorColor: appThemeColors.errorRed,
                                    lastDate:
                                        _selectedEndDate ??
                                        DateTime.now().add(
                                          const Duration(days: 365 * 2),
                                        ),
                                    date: _tasks[index].deadline,
                                    onDateChanged: (date) {
                                      setState(() {
                                        _tasks[index] = _tasks[index].copyWith(
                                          deadline: date,
                                        );
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  CustomTextField(
                                    label: 'Кількість потрібних волонтерів',
                                    initialValue:
                                        _tasks[index].neededPeople
                                            ?.toString() ??
                                        '1',
                                    onChanged: (value) {
                                      _tasks[index] = _tasks[index].copyWith(
                                        neededPeople: int.tryParse(value) ?? 0,
                                      );
                                    },
                                    labelColor: appThemeColors.primaryBlack,
                                    hintText: 'Кількість',
                                    inputType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Введіть кількість';
                                      }
                                      if (int.tryParse(value) == null ||
                                          int.parse(value) <= 0) {
                                        return 'Введіть коректне число > 0';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: IconButton(
                        onPressed: _addTask,
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: appThemeColors.backgroundLightGrey,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Тільки для друзів',
                          style: TextStyleHelper.instance.title16Bold.copyWith(
                            color: appThemeColors.backgroundLightGrey,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _isOnlyFriends,
                          onChanged: (value) {
                            setState(() {
                              _isOnlyFriends = value;
                            });
                          },
                          activeColor: appThemeColors.appBarBg,
                          inactiveTrackColor: appThemeColors.appBarBg,
                          inactiveThumbColor: appThemeColors.primaryWhite,
                          trackOutlineColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          overlayColor: WidgetStateProperty.all(
                            appThemeColors.transparent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Consumer<ProjectViewModel>(
                      builder: (context, viewModel, child) {
                        return CustomElevatedButton(
                          isLoading: viewModel.isSubmitting,
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              String? errorMessage;
                              if (_tasks.isEmpty) {
                                errorMessage =
                                    'Будь ласка, додайте хоча б одне завдання.';
                              } else if (_selectedStartDate == null ||
                                  _selectedEndDate == null) {
                                errorMessage =
                                    'Будь ласка, оберіть дати початку та кінця проєкту.';
                              } else if (_selectedEndDate!.isBefore(
                                _selectedStartDate!,
                              )) {
                                errorMessage =
                                    'Дата кінця не може бути раніше дати початку.';
                              }
                              if (errorMessage != null) {
                                Constants.showErrorMessage(
                                  context,
                                  errorMessage,
                                );
                                return;
                              }

                              if (isEditing) {
                                errorMessage = await viewModel.updateProject(
                                  projectId: widget.projectId!,
                                  title: _titleController.text,
                                  description: _descriptionController.text,
                                  location: _locationController.text,
                                  startDate: _selectedStartDate!,
                                  endDate: _selectedEndDate!,
                                  categories: _selectedCategories,
                                  skills: _selectedSkills,
                                  tasks: _tasks,
                                  city: viewModel.user?.city ?? _selectedCity,
                                  isOnlyFriends: _isOnlyFriends,
                                );
                              } else {
                                errorMessage = await viewModel.createProject(
                                  title: _titleController.text,
                                  description: _descriptionController.text,
                                  location: _locationController.text,
                                  startDate: _selectedStartDate!,
                                  endDate: _selectedEndDate!,
                                  categories: _selectedCategories,
                                  skills: _selectedSkills,
                                  tasks: _tasks,
                                  city: viewModel.user?.city ?? _selectedCity,
                                  isOnlyFriends: _isOnlyFriends,
                                );
                              }

                              if (errorMessage == null) {
                                Constants.showSuccessMessage(
                                  context,
                                  isEditing
                                      ? 'Проєкт "${_titleController.text}" успішно оновлено!'
                                      : 'Проєкт "${_titleController.text}" успішно створено!',
                                );
                                Navigator.of(context).pushReplacementNamed(
                                  AppRoutes.eventListScreen, //TODO
                                );
                              } else {
                                Constants.showErrorMessage(
                                  context,
                                  errorMessage,
                                );
                              }
                            }
                          },
                          text: isEditing
                              ? 'Зберегти зміни'
                              : 'Створити проєкт',
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

  void _populateFormFields(ProjectModel project) {
    _titleController.text = project.title ?? '';
    _descriptionController.text = project.description ?? '';
    _locationController.text = project.locationText ?? '';

    setState(() {
      _selectedStartDate = project.startDate;
      _selectedEndDate = project.endDate;
      _selectedCategories = List.from(project.categories ?? []);
      _selectedSkills = List.from(project.skills ?? []);
      _tasks = List.from(project.tasks ?? []);
      _selectedCity = project.city ?? '';
      _isOnlyFriends = project.isOnlyFriends ?? false;
    });

    final viewModel = Provider.of<ProjectViewModel>(context, listen: false);
    if (project.locationGeo != null) {
      viewModel.setProjectCoordinates(
        project.locationGeo!.latitude,
        project.locationGeo!.longitude,
      );
    }
  }
}
