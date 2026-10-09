/// When false, the UI only offers the 50x25 mm label; large-label code remains compiled.
const bool kEnableLargeLabel = false;

/// U350-only label extras (arrow, KEEP UP RIGHT, MADE IN INDIA). Exact model match.
bool showKeepUpExtras(String vehicleModel) =>
    vehicleModel.trim().toUpperCase() == 'U350';

/// On-screen 50×25 mm preview scale: logical pixels per millimetre.
const double kLabelPreviewPxPerMm = 7.2;
