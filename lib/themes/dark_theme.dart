import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';

class DarkTheme extends ThemeBase {
  DarkTheme({@required int raw}) : super(raw: raw);

  @override
  String get title => S.current.dark_theme;

  @override
  ThemeType get type => ThemeType.dark;

  @override
  ThemeData get themeData => ThemeData(
      fontFamily: 'Lato',
      brightness: Brightness.dark,
      backgroundColor: PaletteExplorerDark.background,
      accentColor: PaletteExplorerDark.indigoGlow, // first gradient color
      scaffoldBackgroundColor: PaletteExplorerDark.background, // second gradient color
      primaryColor: PaletteExplorerDark.background, // third gradient color
      buttonColor: PaletteExplorerDark.primary, // action buttons on dashboard page
      indicatorColor: PaletteExplorerDark.primary, // page indicator
      hoverColor: PaletteExplorerDark.zinc400, // amount hint text (receive page)
      dividerColor: PaletteExplorerDark.divider.withOpacity(0.7),
      hintColor: PaletteExplorerDark.hint, // menu
      dialogBackgroundColor: PaletteExplorerDark.zinc900.withOpacity(0.9),
      cardColor: PaletteExplorerDark.zinc900.withOpacity(0.7), // bottom button (action list)
      textTheme: TextTheme(
          title: TextStyle(
              color: PaletteExplorerDark.foreground, // sync_indicator text
              backgroundColor: PaletteExplorerDark.primary.withOpacity(0.35), // synced sync_indicator
              decorationColor: PaletteExplorerDark.zinc800.withOpacity(0.35) // not synced sync_indicator
          ),
          caption: TextStyle(
            color: PaletteExplorerDark.link, // not synced light
            decorationColor: PaletteExplorerDark.zinc400, // filter icon
          ),
          overline: TextStyle(
              color: PaletteExplorerDark.zinc400, // filter button
              backgroundColor: PaletteExplorerDark.zinc900.withOpacity(0.7), // date section row
              decorationColor: PaletteExplorerDark.zinc400 // icons (transaction and trade rows)
          ),
          subhead: TextStyle(
            color: PaletteExplorerDark.zinc800.withOpacity(0.7), // address button border
            decorationColor: PaletteExplorerDark.zinc400, // copy button (qr widget)
          ),
          headline: TextStyle(
            color: PaletteExplorerDark.zinc300, // qr code
            decorationColor: PaletteExplorerDark.zinc800.withOpacity(0.7), // bottom border of amount (receive page)
          ),
          display1: TextStyle(
            color: PaletteExplorerDark.foreground, // icons color (receive page)
            decorationColor: PaletteExplorerDark.zinc800.withOpacity(0.35), // icons background (receive page)
          ),
          display2: TextStyle(
              color: PaletteExplorerDark.foreground, // text color of tiles (receive page)
              decorationColor: PaletteExplorerDark.zinc900.withOpacity(0.7) // background of tiles (receive page)
          ),
          display3: TextStyle(
              color: PaletteExplorerDark.link, // text color of current tile (receive page)
              decorationColor: PaletteExplorerDark.primary.withOpacity(0.20) // background of current tile (receive page)
          ),
          display4: TextStyle(
              color: PaletteExplorerDark.foreground, // text color of tiles (account list)
              decorationColor: PaletteExplorerDark.zinc900.withOpacity(0.7) // background of tiles (account list)
          ),
          subtitle: TextStyle(
              color: PaletteExplorerDark.link, // text color of current tile (account list)
              decorationColor: PaletteExplorerDark.primary.withOpacity(0.20) // background of current tile (account list)
          ),
          body1: TextStyle(
              color: PaletteExplorerDark.zinc500, // scrollbar thumb
              decorationColor: PaletteExplorerDark.zinc800.withOpacity(0.7) // scrollbar background
          ),
          body2: TextStyle(
            color: PaletteExplorerDark.foreground, // menu header
            decorationColor: PaletteExplorerDark.zinc900.withOpacity(0.7), // menu background
          )
      ),
      primaryTextTheme: TextTheme(
          title: TextStyle(
              color: PaletteExplorerDark.foreground, // title color
              backgroundColor: PaletteExplorerDark.zinc800.withOpacity(0.7) // textfield underline
          ),
          caption: TextStyle(
              color: PaletteExplorerDark.zinc500, // secondary text
              decorationColor: PaletteExplorerDark.zinc800.withOpacity(0.7) // menu divider
          ),
          overline: TextStyle(
            color: PaletteExplorerDark.zinc400, // transaction/trade details titles
            decorationColor: Colors.grey, // placeholder
          ),
          subhead: TextStyle(
              color: PaletteExplorerDark.indigoGlow, // first gradient color (send page)
              decorationColor: PaletteExplorerDark.background // second gradient color (send page)
          ),
          headline: TextStyle(
            color: PaletteExplorerDark.zinc800.withOpacity(0.7), // text field border color (send page)
            decorationColor: PaletteExplorerDark.zinc500, // text field hint color (send page)
          ),
          display1: TextStyle(
              color: PaletteExplorerDark.link, // text field button color (send page)
              decorationColor: PaletteExplorerDark.zinc400 // text field button icon color (send page)
          ),
          display2: TextStyle(
              color: PaletteExplorerDark.foreground, // estimated fee (send page)
              backgroundColor: PaletteExplorerDark.primary, // dot color for indicator on send page
              decorationColor: PaletteExplorerDark.zinc800.withOpacity(0.7) // template dotted border (send page)
          ),
          display3: TextStyle(
              color: PaletteExplorerDark.zinc500, // template new text (send page)
              backgroundColor: PaletteExplorerDark.foreground, // active dot color for indicator on send page
              decorationColor: PaletteExplorerDark.zinc900.withOpacity(0.7) // template background color (send page)
          ),
          display4: TextStyle(
              color: PaletteExplorerDark.foreground, // template title (send page)
              backgroundColor: PaletteExplorerDark.foreground, // icon color on order row (moonpay)
              decorationColor: PaletteExplorerDark.link // receive amount text (exchange page)
          ),
          subtitle: TextStyle(
              color: PaletteExplorerDark.indigoGlow, // first gradient color top panel (exchange page)
              decorationColor: PaletteExplorerDark.background // second gradient color top panel (exchange page)
          ),
          body1: TextStyle(
              color: PaletteExplorerDark.background, // first gradient color bottom panel (exchange page)
              decorationColor: PaletteExplorerDark.background, // second gradient color bottom panel (exchange page)
              backgroundColor: PaletteExplorerDark.foreground // alert right button text
          ),
          body2: TextStyle(
              color: PaletteExplorerDark.zinc800.withOpacity(0.7), // text field border on top panel (exchange page)
              decorationColor: PaletteExplorerDark.zinc800.withOpacity(0.7), // text field border on bottom panel (exchange page)
              backgroundColor: Palette.alizarinRed // alert left button text
          )
      ),
      focusColor: PaletteExplorerDark.zinc800.withOpacity(0.35), // text field button (exchange page)
      accentTextTheme: TextTheme(
        title: TextStyle(
            color: PaletteExplorerDark.zinc900.withOpacity(0.7), // picker background
            backgroundColor: PaletteExplorerDark.zinc800.withOpacity(0.7), // picker divider
            decorationColor: PaletteExplorerDark.zinc900.withOpacity(0.9) // dialog background
        ),
        caption: TextStyle(
          color: PaletteExplorerDark.zinc900.withOpacity(0.7), // container (confirm exchange)
          backgroundColor: PaletteExplorerDark.primary, // button background (confirm exchange)
          decorationColor: PaletteExplorerDark.foreground, // text color (information page)
        ),
        subtitle: TextStyle(
            color: PaletteExplorerDark.foreground, // QR code (exchange trade page)
            backgroundColor: PaletteExplorerDark.zinc800.withOpacity(0.7), // divider (exchange trade page)
            decorationColor: PaletteExplorerDark.primary // crete new wallet button background (wallet list page)
        ),
        headline: TextStyle(
            color: PaletteExplorerDark.indigoGlow, // first gradient color of wallet action buttons (wallet list page)
            backgroundColor: PaletteExplorerDark.background, // second gradient color of wallet action buttons (wallet list page)
            decorationColor: PaletteExplorerDark.foreground // restore wallet button text color (wallet list page)
        ),
        subhead: TextStyle(
            color: PaletteExplorerDark.foreground, // titles color (filter widget)
            backgroundColor: PaletteExplorerDark.zinc800.withOpacity(0.7), // divider color (filter widget)
            decorationColor: PaletteExplorerDark.zinc800.withOpacity(0.35) // checkbox background (filter widget)
        ),
        overline: TextStyle(
          color: PaletteExplorerDark.zinc800.withOpacity(0.7), // checkbox bounds (filter widget)
          decorationColor: PaletteExplorerDark.zinc500, // menu subname
        ),
        display1: TextStyle(
            color: PaletteExplorerDark.indigoGlow, // first gradient color (menu header)
            decorationColor: PaletteExplorerDark.background, // second gradient color(menu header)
            backgroundColor: PaletteExplorerDark.foreground // active dot color
        ),
        display2: TextStyle(
            color: PaletteExplorerDark.zinc900.withOpacity(0.7), // action button color (address text field)
            decorationColor: PaletteExplorerDark.zinc500, // hint text (seed widget)
            backgroundColor: PaletteExplorerDark.foreground.withOpacity(0.5) // text on balance page
        ),
        display3: TextStyle(
            color: PaletteExplorerDark.zinc500, // hint text (new wallet page)
            decorationColor: PaletteExplorerDark.zinc800.withOpacity(0.7), // underline (new wallet page)
            backgroundColor: PaletteExplorerDark.foreground // menu, icons, balance (dashboard page)
        ),
        display4: TextStyle(
            color: PaletteExplorerDark.zinc800.withOpacity(0.7), // switch background (settings page)
            backgroundColor: PaletteExplorerDark.foreground, // icon color on support page (moonpay, github)
            decorationColor: PaletteExplorerDark.zinc500 // hint text (exchange page)
        ),
        body1: TextStyle(
            color: PaletteExplorerDark.zinc500, // indicators (PIN code)
            decorationColor: PaletteExplorerDark.zinc400, // switch (PIN code)
            backgroundColor: PaletteExplorerDark.primary // alert right button
        ),
        body2: TextStyle(
            color: PaletteExplorerDark.primary, // primary buttons
            decorationColor: PaletteExplorerDark.zinc900.withOpacity(0.7), // alert left button
            backgroundColor: PaletteExplorerDark.zinc900 // keyboard bar color
        ),
      ),
      iconTheme: IconThemeData(color: PaletteExplorerDark.zinc400)
  );
}
