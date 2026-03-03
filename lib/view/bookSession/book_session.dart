import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/view/home/home_screen.dart';
import 'package:flutter_projects/provider/connectivity_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/bookSession/skeleton/book_session_screen_skeleton.dart';
import 'package:flutter_projects/view/components/internet_alert.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';
import '../components/reusable_session_card.dart';

class BookSessionScreen extends StatefulWidget {
  final Map<String, dynamic> tutorProfile;
  final Map<String, dynamic> tutor;

  BookSessionScreen({required this.tutorProfile, required this.tutor});

  @override
  _BookSessionScreenState createState() => _BookSessionScreenState();
}

class _BookSessionScreenState extends State<BookSessionScreen> {
  bool isLoading = false;
  int selectedIndex = 0;
  List<DateTime> dateList = [];
  List<String> dayList = [];

  Map<String, dynamic> sessionData = {};
  ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  final random = Random();

  List<Color> borderColors = [
    AppColors.redColor,
    AppColors.lightBlueColor,
    AppColors.lightGreenColor,
    AppColors.orangeColor,
    AppColors.purpleColor,
    AppColors.pinkColor,
    Colors.teal,
    Colors.indigo,
    AppColors.yellowColor,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _fetchTutorAvailableSlots(widget.tutor['id']);
    _scrollController = ScrollController();
  }

  Future<void> _fetchTutorAvailableSlots(int tutorId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    try {
      setState(() {
        isLoading = true;
      });

      // DEBUG: parámetros de entrada
      print(
          '[BookSessionScreen] DEBUG _fetchTutorAvailableSlots tutorId=$tutorId tokenIsNull=${token == null}');

      final response = await getTutorAvailableSlots(token!, tutorId.toString());

      // DEBUG: estructura de la respuesta
      print('[BookSessionScreen] DEBUG response type=${response.runtimeType}');
      final Map<String, dynamic> responseMap = response;
      print(
          '[BookSessionScreen] DEBUG response keys=${responseMap.keys.toList()}');
      if (responseMap.containsKey('data')) {
        final data = responseMap['data'];
        print(
            '[BookSessionScreen] DEBUG response["data"] type=${data.runtimeType}');
        if (data is Map) {
          print(
              '[BookSessionScreen] DEBUG data keys(sample)=${data.keys.take(3).toList()}');
        } else if (data is List) {
          print('[BookSessionScreen] DEBUG data length=${data.length}');
        }
      }

      DateTime startDate = DateTime.now();
      DateTime endDate = startDate.add(Duration(days: 10));
      _generateDateAndDayList(startDate, endDate);

      Map<String, dynamic> formattedSessionData = {};

      // Intentar usar response['data'] si existe, sino el response directamente
      final dynamic source =
          responseMap.containsKey('data') ? responseMap['data'] : responseMap;

      if (source is Map) {
        source.forEach((groupName, subjects) {
          if (subjects is Map) {
            subjects.forEach((subjectName, subjectData) {
              final List<dynamic> slots = subjectData["slots"] ?? [];

              for (var slot in slots) {
                DateTime slotDate = DateTime.parse(slot["start_time"].trim());
                String formattedDate =
                    DateFormat('dd MMM yyyy').format(slotDate);

                if (!formattedSessionData.containsKey(formattedDate)) {
                  formattedSessionData[formattedDate] = [];
                }

                formattedSessionData[formattedDate].add({
                  "id": slot["id"],
                  "start_time": slot["start_time"].trim(),
                  "end_time": slot["end_time"],
                  "spaces": slot["spaces"],
                  "session_fee": slot["session_fee"],
                  "total_booked": slot["total_booked"],
                  "description": slot["description"] ?? "Sin descripción",
                  "students": slot["students"],
                  "formatted_time_range":
                      "${DateFormat('hh:mm a').format(DateTime.parse(slot["start_time"].trim()))} - ${DateFormat('hh:mm a').format(DateTime.parse(slot["end_time"].trim()))}",
                  "subject": subjectData["info"]?["subject"],
                  "group": groupName,
                });
              }
            });
          }
        });
      } else if (source is List) {
        // Si la API devuelve una lista plana de slots
        print(
            '[BookSessionScreen] DEBUG source is List (slots length=${source.length})');
        for (final slot in source) {
          try {
            DateTime slotDate = DateTime.parse(slot["start_time"].trim());
            String formattedDate = DateFormat('dd MMM yyyy').format(slotDate);

            if (!formattedSessionData.containsKey(formattedDate)) {
              formattedSessionData[formattedDate] = [];
            }

            formattedSessionData[formattedDate].add({
              "id": slot["id"],
              "start_time": slot["start_time"].trim(),
              "end_time": slot["end_time"],
              "spaces": slot["spaces"],
              "session_fee": slot["session_fee"],
              "total_booked": slot["total_booked"],
              "description": slot["description"] ?? "Sin descripción",
              "students": slot["students"],
              "formatted_time_range":
                  "${DateFormat('hh:mm a').format(DateTime.parse(slot["start_time"].trim()))} - ${DateFormat('hh:mm a').format(DateTime.parse(slot["end_time"].trim()))}",
              "subject": slot["subject"],
              "group": slot["group"],
            });
          } catch (e) {
            print('[BookSessionScreen] DEBUG error parsing slot item: $e');
          }
        }
      } else {
        print(
            '[BookSessionScreen] WARN unexpected source data type: ${source.runtimeType}');
      }

      setState(() {
        sessionData = formattedSessionData;
      });

      // Buscar la primera fecha con sesiones disponibles
      int firstAvailableIndex = -1;
      DateTime? firstAvailableDate;

      for (int i = 0; i < dateList.length; i++) {
        String dateKey = DateFormat('dd MMM yyyy').format(dateList[i]);
        if (sessionData.containsKey(dateKey)) {
          firstAvailableIndex = i;
          firstAvailableDate = dateList[i];
          break;
        }
      }

      if (firstAvailableIndex != -1 && firstAvailableDate != null) {
        setState(() {
          selectedIndex = firstAvailableIndex;
        });
        await _fetchSessionsForSelectedDate(firstAvailableDate);
      }
    } catch (e) {
      print("Error fetching tutor available slots: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchSessionsForSelectedDate(DateTime date) async {
    // No usamos token aquí porque no hacemos refetch; mantenemos datos en memoria

    try {
      setState(() {
        isLoading = true;
      });
      print(
          '[BookSessionScreen] DEBUG _fetchSessionsForSelectedDate date=$date selectedIndex=$selectedIndex');
      // Nota: ya tenemos los datos en sessionData; si se requiere refetch por fecha, descomentar:
      // final response = await getTutorAvailableSlots(token!, widget.tutor['id'].toString());
      // print('[BookSessionScreen] DEBUG refetch response keys=${response is Map ? response.keys.toList() : response.runtimeType}');
      // Mantener sessionData como está, solo actualizar UI
    } catch (e) {
      print('[BookSessionScreen] ERROR _fetchSessionsForSelectedDate: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _generateDateAndDayList(DateTime startDate, DateTime endDate) {
    List<DateTime> dates = [];
    List<String> days = [];

    for (var date = startDate;
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        date = date.add(Duration(days: 1))) {
      dates.add(date);
      days.add(DateFormat('EEE').format(date));
    }

    setState(() {
      dateList = dates;
      dayList = days;
    });
  }

  Color getRandomBorderColor() {
    return borderColors[random.nextInt(borderColors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, _) {
        if (!connectivityProvider.isConnected) {
          return Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: Center(
              child: InternetAlertDialog(
                onRetry: () async {
                  await connectivityProvider.checkInitialConnection();
                },
              ),
            ),
          );
        }

        return WillPopScope(
          onWillPop: () async {
            return !isLoading;
          },
          child: Scaffold(
            backgroundColor: AppColors.primaryGreen,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(150.0),
              child: Container(
                color: AppColors.primaryGreen,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: AppBar(
                    backgroundColor: AppColors.whiteColor,
                    forceMaterialTransparency: true,
                    centerTitle: false,
                    elevation: 0,
                    titleSpacing: 0,
                    title: Text(
                      'Reservar Sesión',
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: FontSize.scale(context, 20),
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    leading: Padding(
                      padding: const EdgeInsets.only(top: 3.0),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.arrow_back_ios,
                            size: 20, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => HomeScreen()),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                    flexibleSpace: Align(
                      alignment: Alignment.bottomCenter,
                      child: isLoading
                          ? DateSelectorSkeleton()
                          : _buildDateSelector(),
                    ),
                  ),
                ),
              ),
            ),
            body: isLoading ? BookSessionSkeleton() : _buildSessionList(),
          ),
        );
      },
    );
  }

  // Devuelve los días con disponibilidad real
  Set<DateTime> getAvailableDays() {
    Set<DateTime> days = {};
    sessionData.forEach((dateKey, sessions) {
      if (sessions is List && sessions.isNotEmpty) {
        DateTime day = DateFormat('dd MMM yyyy').parse(dateKey);
        days.add(DateTime(day.year, day.month, day.day));
      }
    });
    return days;
  }

  // Devuelve los horarios de inicio válidos para el día seleccionado
  List<DateTime> getAvailableStartTimesForSelectedDate() {
    String selectedDate =
        DateFormat('dd MMM yyyy').format(dateList[selectedIndex]);
    List<DateTime> availableTimes = [];
    if (sessionData.containsKey(selectedDate)) {
      for (var session in sessionData[selectedDate]) {
        DateTime start = DateTime.parse(session['start_time']);
        DateTime end = DateTime.parse(session['end_time']);
        DateTime lastStart = end.subtract(Duration(minutes: 20));
        for (DateTime t = start;
            !t.isAfter(lastStart);
            t = t.add(Duration(minutes: 20))) {
          availableTimes.add(t);
        }
      }
    }
    return availableTimes;
  }

  // Opciones rápidas: los próximos 3 horarios disponibles
  List<DateTime> getQuickStartTimes() {
    List<DateTime> all = getAvailableStartTimesForSelectedDate();
    return all.take(3).toList();
  }

  // Modifica el _buildDateSelector para solo habilitar días con disponibilidad
  Widget _buildDateSelector() {
    if (isLoading) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: AppColors.primaryGreen,
            strokeWidth: 2.0,
          ),
        ),
      );
    }

    if (dateList.isEmpty || dayList.isEmpty) {
      return Container(
        height: 80,
        child: Center(
          child: Text('No dates available'),
        ),
      );
    }

    Set<DateTime> availableDays = getAvailableDays();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final offset = selectedIndex * 100.0;
        final maxScrollExtent = _scrollController.position.maxScrollExtent;
        if (offset <= maxScrollExtent) {
          _scrollController.jumpTo(offset);
        } else {
          _scrollController.jumpTo(maxScrollExtent);
        }
      }
    });

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        border: Border(
          bottom: BorderSide(width: 2, color: AppColors.bookBorderPinkColor),
        ),
      ),
      child: ListView.builder(
        key: PageStorageKey('dateListKey'),
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: dateList.length,
        itemBuilder: (context, index) {
          bool isSelected = selectedIndex == index;
          DateTime day = dateList[index];
          bool isAvailable =
              availableDays.contains(DateTime(day.year, day.month, day.day));

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedIndex = index;
              });
              _fetchSessionsForSelectedDate(dateList[index]);
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.navbar.withOpacity(0.8)
                      : AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                child: Column(
                  children: [
                    Text(
                      DateFormat('dd MMM').format(dateList[index]),
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: FontSize.scale(context, 17),
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      dayList[index],
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: FontSize.scale(context, 16),
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Ejemplo de selector de hora usando los horarios válidos
  Widget buildHourSelector() {
    List<DateTime> availableTimes = getAvailableStartTimesForSelectedDate();
    if (availableTimes.isEmpty) {
      return Text('No hay horarios disponibles');
    }
    return DropdownButton<DateTime>(
      value: availableTimes.first,
      items: availableTimes.map((dt) {
        return DropdownMenuItem<DateTime>(
          value: dt,
          child: Text(DateFormat('HH:mm').format(dt)),
        );
      }).toList(),
      onChanged: (dt) {
        // Actualiza el estado según la selección
      },
    );
  }

  // Ejemplo de opciones rápidas
  Widget buildQuickHourOptions() {
    List<DateTime> quickTimes = getQuickStartTimes();
    if (quickTimes.isEmpty) {
      return Text('No hay horarios rápidos');
    }
    return Row(
      children: quickTimes.map((dt) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: ElevatedButton(
            onPressed: () {
              // Actualiza el estado según la selección
            },
            child: Text(DateFormat('HH:mm').format(dt)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSessionList() {
    if (dateList.isEmpty) {
      return Center(
        child: Text(
          'Listing not available',
          style: TextStyle(
            color: AppColors.greyColor,
            fontSize: FontSize.scale(context, 14),
            fontFamily: 'SF-Pro-Text',
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.normal,
          ),
        ),
      );
    }

    // Formatear la fecha seleccionada para acceder a los datos
    String selectedDate =
        DateFormat('dd MMM yyyy').format(dateList[selectedIndex]);

    print(
        '[BookSessionScreen] DEBUG selectedDate=$selectedDate hasData=${sessionData.containsKey(selectedDate)} totalDates=${sessionData.keys.length}');

    if (sessionData.containsKey(selectedDate)) {
      List<dynamic> sessions = sessionData[selectedDate];
      print('[BookSessionScreen] DEBUG sessionsCount=${sessions.length}');

      if (sessions.isEmpty) {
        return Center(
          child: Text(
            'No hay sesiones disponibles para la fecha seleccionada',
            style: TextStyle(
              color: AppColors.whiteColor,
              fontSize: FontSize.scale(context, 14),
              fontFamily: 'SF-Pro-Text',
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.normal,
            ),
          ),
        );
      }

      return ListView.builder(
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          print(session.toString());
          final totalSlots = session['spaces'];
          final slotsLeft = session['spaces'] - session['total_booked'];
          final bookedSlots = session['total_booked'];

          return Container(
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              border: Border(
                bottom: BorderSide(color: getRandomBorderColor(), width: 1.5),
              ),
            ),
            child: SessionCard(
              slotsLeft: slotsLeft,
              totalSlots: totalSlots,
              bookedSlots: bookedSlots,
              borderColor: getRandomBorderColor(),
              description: session['description'],
              sessionDate: selectedDate,
              sessionData: session,
              tutorProfile: widget.tutorProfile,
              onSessionUpdated: () {
                _fetchTutorAvailableSlots(widget.tutorProfile['id']);
              },
            ),
          );
        },
      );
    } else {
      return Center(
        child: Text(
          'No hay sesiones disponibles para la fecha seleccionada',
          style: TextStyle(
            color: AppColors.whiteColor,
            fontSize: FontSize.scale(context, 14),
            fontFamily: 'SF-Pro-Text',
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.normal,
          ),
        ),
      );
    }
  }
}
