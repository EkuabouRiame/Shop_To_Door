import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ShopToDoorApp());
}

class ShopToDoorApp extends StatelessWidget {
  const ShopToDoorApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryYellow = Color(0xFFFFC107);
    const lightYellow = Color(0xFFFFE082);
    const darkYellow = Color(0xFFB77900);
    const darkText = Color(0xFF1F2937);
    const greyText = Color(0xFF6B7280);
    const pageBackground = Color(0xFFFFF8D6);

    return MaterialApp(
      title: 'Shop To Door',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,

        // ======================================================
        // SHOP TO DOOR YELLOW THEME
        // ======================================================

        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryYellow,
          brightness: Brightness.light,
        ).copyWith(
          primary: primaryYellow,
          onPrimary: darkText,
          secondary: darkYellow,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: darkText,
        ),

        // ======================================================
        // MAIN APP BACKGROUND
        // ======================================================

        scaffoldBackgroundColor: pageBackground,

        // ======================================================
        // APP BAR
        // ======================================================

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: darkText,
          elevation: 0,
          centerTitle: false,
        ),

        // ======================================================
        // BOTTOM NAVIGATION
        // ======================================================

        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 3,

          indicatorColor: lightYellow,

          labelTextStyle:
              WidgetStateProperty.resolveWith<TextStyle>(
            (states) {
              if (states.contains(
                WidgetState.selected,
              )) {
                return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                );
              }

              return const TextStyle(
                fontSize: 12,
                color: greyText,
              );
            },
          ),

          iconTheme:
              WidgetStateProperty.resolveWith<IconThemeData>(
            (states) {
              if (states.contains(
                WidgetState.selected,
              )) {
                return const IconThemeData(
                  color: darkYellow,
                );
              }

              return const IconThemeData(
                color: greyText,
              );
            },
          ),
        ),

        // ======================================================
        // CARDS
        // ======================================================

        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),

        // ======================================================
        // TEXT FIELDS
        // ======================================================

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: primaryYellow,
              width: 1.5,
            ),
          ),

          prefixIconColor: darkYellow,
          suffixIconColor: greyText,

          labelStyle: const TextStyle(
            color: greyText,
          ),

          floatingLabelStyle: const TextStyle(
            color: darkYellow,
            fontWeight: FontWeight.w600,
          ),
        ),

        // ======================================================
        // ELEVATED BUTTONS
        // ======================================================

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryYellow,
            foregroundColor: darkText,

            minimumSize: const Size(
              double.infinity,
              48,
            ),

            elevation: 1,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // ======================================================
        // OUTLINED BUTTONS
        // ======================================================

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: darkYellow,

            side: const BorderSide(
              color: primaryYellow,
              width: 1.2,
            ),

            minimumSize: const Size(
              double.infinity,
              48,
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // ======================================================
        // TEXT BUTTONS
        // ======================================================

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: darkYellow,
          ),
        ),

        // ======================================================
        // ICON BUTTONS
        // ======================================================

        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: darkYellow,
          ),
        ),

        // ======================================================
        // CHECKBOX
        // ======================================================

        checkboxTheme: CheckboxThemeData(
          fillColor:
              WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(
                WidgetState.selected,
              )) {
                return primaryYellow;
              }

              return null;
            },
          ),
          checkColor:
              WidgetStateProperty.all<Color>(
            darkText,
          ),
        ),

        // ======================================================
        // RADIO BUTTON
        // ======================================================

        radioTheme: RadioThemeData(
          fillColor:
              WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(
                WidgetState.selected,
              )) {
                return darkYellow;
              }

              return greyText;
            },
          ),
        ),

        // ======================================================
        // SWITCH
        // ======================================================

        switchTheme: SwitchThemeData(
          thumbColor:
              WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(
                WidgetState.selected,
              )) {
                return darkYellow;
              }

              return Colors.white;
            },
          ),

          trackColor:
              WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(
                WidgetState.selected,
              )) {
                return lightYellow;
              }

              return Colors.grey.shade300;
            },
          ),
        ),

        // ======================================================
        // PROGRESS INDICATORS
        // ======================================================

        progressIndicatorTheme:
            const ProgressIndicatorThemeData(
          color: primaryYellow,
        ),

        // ======================================================
        // SLIDER
        // ======================================================

        sliderTheme: const SliderThemeData(
          activeTrackColor: primaryYellow,
          thumbColor: darkYellow,
          inactiveTrackColor: lightYellow,
        ),

        // ======================================================
        // FLOATING ACTION BUTTON
        // ======================================================

        floatingActionButtonTheme:
            const FloatingActionButtonThemeData(
          backgroundColor: primaryYellow,
          foregroundColor: darkText,
        ),

        // ======================================================
        // DIVIDERS
        // ======================================================

        dividerTheme: DividerThemeData(
          color: Colors.grey.shade200,
          thickness: 1,
        ),

        // ======================================================
        // SNACKBAR
        // ======================================================

        snackBarTheme: SnackBarThemeData(
          backgroundColor: darkText,
          contentTextStyle: const TextStyle(
            color: Colors.white,
          ),
          actionTextColor: lightYellow,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        // ======================================================
        // CHIP
        // ======================================================

        chipTheme: ChipThemeData(
          backgroundColor: lightYellow,
          selectedColor: primaryYellow,
          labelStyle: const TextStyle(
            color: darkText,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      // ========================================================
      // LOGIN REMAINS THE FIRST SCREEN
      // ========================================================

      home: const LoginScreen(),
    );
  }
}