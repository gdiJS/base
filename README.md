# GDI.js - Javascript runtime for windows

API Documentation: https://gdi.sh/docs
v8 Documentation: https://v8.dev/docs
JS Reference: https://developer.mozilla.org/en-US/docs/Web/JavaScript

### About
GDI.js is an experimental javascript runtime that implements win32 api calls into v8 interface.
Started as a personal digital assistant project at 2009. Switched from Mozilla's spidermonkey to Google's V8 engine at 2014.
It's gained attraction in corporate environment and eventually became a drop-in replacement of node.js with extra arms.

### Key differences
- Multithreading: While other runtimes driven by async event loops to maximize I/O throughput, GDI.js uses standard windows message loop with multithreaded operations for sake of simplicity.
- Native desktop: GDI.js is just a native desktop application. It can directly access to serial ports, activex objects, desktop, network, gpu, external DLL's without requiring any extra module.
- Smaller payload: Bare minimum stack, GDI.exe and engine.dll is just 13.4mb while implementing modern ECMA-262 standard (for comparison, node.exe is around 90mb today)

### Usage scenerios
- Rapid JS prototyping hence the fast bootup
- Build monitoring applications for your arduino projects
- Create data sources for your desktop widgets
- Connect to web services, process and manipulate data, send it back

### Building instructions
- Fork the ´engine´ repository and build the ´engine.dll´ by using visual studio 2015. Main branch pre-configured for dll deployment.
- Fork the ´boot´ repository and create the ´engine.js´ by running ´merge.bat´
- Drop the both files into project sources and run ´res.bat resources.rc´ to generate resource file
- Generate the executable by compiling gdi.dpk

### Uses
- V8 project, Google Inc, https://v8.dev/
- Sqlite3 Interface, Tim Anderson <tim@itwriting.com>
- MD5 unit, Dimka Maslov <mail@endimus.com>
- CPUID, Roelof Engelbrecht <roelof@cox-internet.com>
- XSuperObject, Onur YILDIZ <https://github.com/onryldz>
- JSONEx, Randolph <rilyu@sina.com>
- DISystemCompat, Ralf Junker <delphi@yunqa.de>
- BASS, Un4seen Developments <support@un4seen.com>
- v8 headers, Ryan Zhou, <zhouzuoji@outlook.com>
- SendKeys, Ken Henderson <khen@compuserve.com>
- SetupAPI, Robert Marquardt <robert_marquardt@gmx.de>
- ModuleLoader from Project JEDI, http://delphi-jedi.org

GDI.js is a free project and a result of the collective efforts of
independent developers who may be unaware of where, when and how
their contributions are utilized. Please honor their work by citing
the original developers when incorporating their work into your own projects.

Software distributed under the License is distributed on an
"AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
implied. See the License.MD for the specific language governing
rights and limitations under the License.

-------------------------------------

Created by PsyChip
<root@psychip.net>
May 2024

.eof