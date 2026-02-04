namespace Tempo {
    /**
     * A simple debug logger for tracking application events.
     * 
     * This class provides consistent formatting for debug output
     * including timestamps and log levels.
     */
    public class DebugLogger : Object {
        
        private static DebugLogger? instance = null;
        
        public static DebugLogger get_instance() {
            if (instance == null) {
                instance = new DebugLogger();
            }
            return instance;
        }
        
        private DebugLogger() {
            // Private constructor for singleton
        }
        
        public void log(string message) {
            print_formatted("INFO", message);
        }
        
        public void warning(string message) {
            print_formatted("WARN", message);
        }
        
        public void error(string message) {
            print_formatted("ERROR", message);
        }
        
        private void print_formatted(string level, string message) {
            var now = new DateTime.now_local();
            print("[%s] [%s] %s\n", now.format("%H:%M:%S.%f"), level, message);
        }
    }
}
