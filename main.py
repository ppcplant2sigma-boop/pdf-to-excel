import os
import sys
import time
import threading
import queue
import traceback
from pathlib import Path

from kivy.app import App
from kivy.clock import Clock
from kivy.core.window import Window
from kivy.graphics import Color, RoundedRectangle
from kivy.metrics import dp
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.modalview import ModalView
from kivy.uix.scrollview import ScrollView

try:
    import engine
except Exception:
    engine = None
    _dump = sys.exc_info()
    try:
        with open(str(Path.home() / "startup_error.txt"), "a") as fh:
            fh.write("".join(traceback.format_exception(*_dump)) + "\n")
    except Exception:
        pass

ACCENT = (0.176, 0.549, 0.941, 1)
ACCENT_DARK = (0.122, 0.435, 0.816, 1)
BG = (1, 1, 1, 1)
PANEL = (0.957, 0.965, 0.984, 1)
TEXT = (0.102, 0.125, 0.188, 1)
MUTED = (0.373, 0.42, 0.49, 1)


def crash_log_path():
    try:
        from android import storage
        d = storage.app_storage_dir()
        os.makedirs(d, exist_ok=True)
        return os.path.join(d, "crash.log")
    except Exception:
        p = str(Path.home())
        os.makedirs(p, exist_ok=True)
        return os.path.join(p, "crash.log")


def dump_crash(exc, tag="main"):
    try:
        tb = "".join(traceback.format_exception(type(exc), exc, exc.__traceback__))
    except Exception:
        tb = "traceback unavailable: %r" % (exc,)
    entry = "[%s] (%s) %s\n" % (time.strftime("%Y-%m-%d %H:%M:%S"), tag, tb)
    try:
        with open(crash_log_path(), "a") as fh:
            fh.write(entry)
        sys.stderr.write("CRASH SAVED -> " + crash_log_path() + "\n")
    except Exception:
        pass
    return entry


def _excepthook(t, v, tb):
    dump_crash(v)
    try:
        sys.__excepthook__(t, v, tb)
    except Exception:
        pass


sys.excepthook = _excepthook

_o_thead_hook = getattr(threading, "excepthook", None)


def _thead_hook(args):
    dump_crash(args.exc_value, tag="thread " + str(getattr(args, "thread", "?")))
    if _o_thead_hook is not None:
        try:
            _o_thead_hook(args)
        except Exception:
            pass


try:
    threading.excepthook = _thead_hook
except Exception:
    pass


def primary_storage():
    if os.environ.get("ANDROID_ARGUMENT") is None:
        return os.path.expanduser("~")
    try:
        from android import storage
        return storage.primary_external_storage_path()
    except Exception:
        return os.environ.get("EXTERNAL_STORAGE", "/sdcard")


def default_browse_path():
    base = primary_storage()
    for sub in ("Download", "Documents", "DCIM"):
        p = os.path.join(base, sub)
        if os.path.isdir(p):
            return p
    return base if os.path.isdir(base) else "/"


def save_dir():
    app = App.get_running_app()
    if app is not None:
        try:
            d = app.user_data_dir
            os.makedirs(d, exist_ok=True)
            return d
        except Exception:
            pass
    d = str(Path.home())
    os.makedirs(d, exist_ok=True)
    return d


def is_pdf(path):
    return str(path).lower().endswith(".pdf")


def pdf_dir():
    base = primary_storage()
    candidates = ["Download", "Documents", "DCIM"]
    for sub in candidates:
        p = os.path.join(base, sub)
        if os.path.isdir(p):
            try:
                if any(is_pdf(n) for n in os.listdir(p)):
                    return p
            except Exception:
                pass
    for sub in candidates:
        p = os.path.join(base, sub)
        if os.path.isdir(p):
            return p
    return base if os.path.isdir(base) else "/"


class Card(BoxLayout):

    def __init__(self, accent=False, **kw):
        super().__init__(**kw)
        self.accent = accent
        self.bind(pos=self._redraw, size=self._redraw)

    def _redraw(self, *a):
        self.canvas.before.clear()
        with self.canvas.before:
            if self.accent:
                Color(*ACCENT, opacity=1)
            else:
                Color(1, 1, 1, 0.95)
            RoundedRectangle(pos=self.pos, size=self.size,
                             radius=[dp(18), dp(18), dp(18), dp(18)])


class PdfToExcelApp(App):

    def build(self):
        try:
            return self._build_ok()
        except Exception:
            entry = dump_crash(sys.exc_info()[1])
            return self._crash_screen(entry)

    def _build_ok(self):
        Window.clearcolor = BG
        self.selected_file = None
        self.busy = False
        self.log_lines = []
        self.q = queue.Queue()
        self._pick_modal = None

        root = BoxLayout(orientation="vertical", padding=dp(14), spacing=dp(10))

        banner = Card(accent=True, size_hint_y=None, height=dp(116))
        hb = BoxLayout(orientation="vertical", padding=(dp(16), dp(6), dp(16), dp(6)),
                       spacing=dp(0))
        hb.add_widget(Label(text="PDF to Excel", bold=True, font_size=dp(27),
                            color=(1, 1, 1, 1), size_hint_y=None, height=dp(46),
                            halign="center"))
        hb.add_widget(Label(text="Tables . Text . Pictures  --&gt;  one clean sheet",
                            font_size=dp(13), color=(0.88, 0.94, 1, 1),
                            size_hint_y=None, height=dp(32), halign="center"))
        hb.add_widget(Label(text="v7   .   100% offline   .   by Er. Durgesh Pandey   .   build cb0eac04",
                            font_size=dp(11), color=(0.9, 0.95, 1, 0.85),
                            size_hint_y=None, height=dp(22), halign="center"))
        banner.add_widget(hb)
        root.add_widget(banner)

        card = Card(size_hint_y=None, height=dp(190))
        box = BoxLayout(orientation="vertical", padding=dp(14), spacing=dp(8))
        select = Button(text="1.  Select PDF File", size_hint_y=None, height=dp(46),
                        background_normal="", background_color=ACCENT,
                        color=(1, 1, 1, 1), bold=True, font_size=dp(15))
        select.bind(on_release=lambda *a: self.open_picker())
        box.add_widget(select)

        self.file_label = Label(text="(no file selected)", font_size=dp(13), color=MUTED,
                                size_hint_y=None, height=dp(24), halign="center",
                                shorten=True)
        box.add_widget(self.file_label)

        self.status = Label(text="Ready. Choose a PDF to begin.", font_size=dp(13),
                            color=ACCENT_DARK, size_hint_y=None, height=dp(22),
                            halign="center")
        box.add_widget(self.status)

        convert = Button(text="2.  Convert to Excel", size_hint_y=None, height=dp(46),
                         background_normal="", background_color=ACCENT_DARK,
                         color=(1, 1, 1, 1), bold=True, font_size=dp(15))
        convert.bind(on_release=lambda *a: self.start_convert())
        box.add_widget(convert)
        card.add_widget(box)
        root.add_widget(card)

        logcard = Card()
        lb = BoxLayout(orientation="vertical", padding=(dp(12), dp(10), dp(12), dp(10)),
                       spacing=dp(6))
        lb.add_widget(Label(text="Activity", bold=True, font_size=dp(12),
                            color=ACCENT_DARK, size_hint_y=None, height=dp(24)))
        self.log_box = Label(text="", markup=True, color=(0.2, 0.32, 0.55, 1),
                             size_hint_y=None, height=dp(200), valign="top",
                             halign="left", text_size=(0, None))

        def _fit_log(*_a):
            self.log_box.text_size = (self.log_box.width, None)
            self.log_box.height = max(dp(200), self.log_box.texture_size[1])

        self.log_box.bind(width=_fit_log, texture_size=_fit_log)
        scroll = ScrollView(size_hint=(1, 1))
        scroll.add_widget(self.log_box)
        lb.add_widget(scroll)
        logcard.add_widget(lb)
        root.add_widget(logcard)

        Clock.schedule_interval(self.drain_queue, 0.15)
        return root

    def _crash_screen(self, entry):
        root = BoxLayout(orientation="vertical", padding=dp(12), spacing=dp(8))
        root.add_widget(Label(
            text="Something went wrong during startup.",
            bold=True, color=(0.85, 0.2, 0.2, 1), size_hint_y=None, height=dp(28)))
        body = Label(text=entry, font_size=dp(12), color=TEXT, valign="top",
                     halign="left", size_hint_y=None, height=dp(200),
                     text_size=(0, None))

        def _fit_body(*_a):
            body.text_size = (body.width, None)
            body.height = max(dp(200), body.texture_size[1])

        body.bind(size=_fit_body, texture_size=_fit_body)
        sc = ScrollView()
        sc.add_widget(body)
        root.add_widget(sc)
        root.add_widget(Label(
            text="Details also saved to:\n" + crash_log_path(),
            font_size=dp(11), color=MUTED, size_hint_y=None, height=dp(40)))
        return root

    def _init_android_picker(self):
        if getattr(self, "_picker_bound", False):
            return True
        if os.environ.get("ANDROID_ARGUMENT") is None:
            return False
        try:
            from android import activity, mActivity
            activity.bind(on_activity_result=self._on_activity_result)
            self._mActivity = mActivity
            self._picker_bound = True
            return True
        except Exception:
            return False

    def open_picker(self):
        if self.busy:
            return
        self._copy_error = None
        if not self._init_android_picker():
            self._custom_picker_fallback()
            return
        from jnius import autoclass
        try:
            Intent = autoclass('android.content.Intent')
            intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
            intent.setType('application/pdf')
            intent.addCategory(Intent.CATEGORY_OPENABLE)
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            self._mActivity.startActivityForResult(intent, 7001)
            self.status.text = "Pick a PDF file..."
        except Exception:
            self._custom_picker_fallback()

    def _on_activity_result(self, request_code, result_code, data):
        if request_code == 7002:
            self.busy = False
            if result_code == 0 or data is None:
                self.status.text = "Save cancelled - internal copy kept."
                return
            try:
                uri = data.getData()
                from jnius import autoclass
                from android import mActivity
                resolver = mActivity.getContentResolver()
                src = getattr(self, "_save_src", None)
                if src and uri is not None:
                    out = resolver.openOutputStream(uri)
                    with open(src, "rb") as fh:
                        while True:
                            chunk = fh.read(65536)
                            if not chunk:
                                break
                            out.write(chunk)
                    out.flush()
                    out.close()
                    self.status.text = "Success - file saved at your chosen location"
                else:
                    self.status.text = "Save cancelled - internal copy kept."
            except Exception as e:
                self.status.text = "Save error: " + repr(e)[:60]
            return
        if request_code != 7001:
            return
        if result_code == 0 or data is None:
            self.status.text = "Selection cancelled"
            return
        try:
            uri = data.getData()
        except Exception:
            uri = None
        if uri is None:
            self.status.text = "No file chosen"
            return
        p = self._saf_copy(str(uri.toString()))
        if p:
            self.selected_file = p
            self.file_label.text = os.path.basename(p)
            self.status.text = "File ready. Press Convert."
        else:
            self.selected_file = None
            if self._copy_error:
                self.status.text = "Read error: " + self._copy_error[:90]
            else:
                self.status.text = "Could not read that file"

    def _saf_copy(self, uri):
        from jnius import autoclass
        PythonActivity = autoclass('org.kivy.android.PythonActivity')
        resolver = PythonActivity.mActivity.getContentResolver()
        Uri = autoclass('android.net.Uri')
        parsed = Uri.parse(uri)

        try:
            Intent = autoclass('android.content.Intent')
            PythonActivity.mActivity.takePersistableUriPermission(
                parsed, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        except Exception:
            pass

        filename = "file.pdf"
        try:
            cursor = resolver.query(parsed, None, None, None, None)
            if cursor is not None and cursor.moveToFirst():
                idx = cursor.getColumnIndex("_display_name")
                if idx >= 0:
                    nm = cursor.getString(idx)
                    if nm:
                        filename = nm
        except Exception:
            pass

        if not str(filename).lower().endswith(".pdf"):
            filename = str(filename) + ".pdf"

        out_path = os.path.join(save_dir(), str(filename))
        try:
            if os.path.exists(out_path):
                os.remove(out_path)
        except Exception:
            pass

        try:
            Paths = autoclass('java.nio.file.Paths')
            Files = autoclass('java.nio.file.Files')
            stream = resolver.openInputStream(parsed)
            Files.copy(stream, Paths.get(out_path))
            stream.close()
            return out_path
        except Exception as e:
            self._copy_error = "nio: " + repr(e)

        try:
            FileInputStream = autoclass('java.io.FileInputStream')
            raw = resolver.openFileDescriptor(parsed, "r")
            fis = FileInputStream(raw.getFileDescriptor())
            with open(out_path, "wb") as fh:
                try:
                    buf = bytearray(65536)
                    while True:
                        n = fis.read(buf)
                        if n <= 0:
                            break
                        fh.write(buf[:n])
                except Exception:
                    fh.seek(0)
                    fh.truncate()
                    while True:
                        b = fis.read()
                        if b < 0:
                            break
                        fh.write(bytes([b]))
            fis.close()
            return out_path
        except Exception as e:
            self._copy_error = "fis: " + repr(e)
            return None

    def _custom_picker_fallback(self):
        if self.busy:
            return
        self._pick_modal = None
        self._show_picker(pdf_dir(), [pdf_dir()])

    def _show_picker(self, start_path, stack):
        entries = []
        try:
            entries = sorted(os.listdir(start_path), key=str.lower)
        except Exception:
            entries = []

        dirs = []
        files = []
        for name in entries:
            full = os.path.join(start_path, name)
            try:
                if os.path.isdir(full):
                    dirs.append(name)
            except Exception:
                continue
        for name in entries:
            full = os.path.join(start_path, name)
            try:
                if os.path.isfile(full) and is_pdf(name):
                    files.append(name)
            except Exception:
                continue

        content = BoxLayout(orientation="vertical", padding=dp(8), spacing=dp(6))
        header = BoxLayout(size_hint_y=None, height=dp(38), spacing=dp(8))
        if start_path not in stack or len(stack) > 1:
            header.add_widget(Button(text=".. (Up)", background_color=(0.4, 0.45, 0.52, 1),
                                     bold=True, on_release=lambda *a: self._go_up(stack)))
        else:
            header.add_widget(Label(text="", size_hint_x=None, width=dp(60)))
        header.add_widget(Label(text=start_path, color=MUTED, font_size=dp(12),
                                shorten=True, halign="center"))
        header.add_widget(Button(text="Cancel", background_color=(0.55, 0.58, 0.64, 1),
                                 size_hint_x=None, width=dp(70),
                                 on_release=lambda *a: self._close_picker()))
        content.add_widget(header)

        if not dirs and not files:
            content.add_widget(Label(text="No PDF files found here.\nGo up or open another folder.",
                                     color=MUTED, font_size=dp(13), size_hint_y=None, height=dp(60)))
        else:
            scroll = ScrollView(size_hint=(1, 1))
            rows = BoxLayout(orientation="vertical", size_hint_y=None, spacing=dp(3))
            rows.bind(minimum_height=rows.setter("height"))

            for d in dirs[:300]:
                b = Button(text="> " + d, halign="left", valign="middle",
                           size_hint_y=None, height=dp(42),
                           background_normal="", background_color=PANEL,
                           color=TEXT, font_size=dp(14), shorten=True)
                b.bind(size=lambda w, *_: setattr(w, "text_size", (w.width - 10, None)))
                b.bind(on_release=lambda *a, dd=d, p=start_path: self._enter_dir(p, dd, stack))
                rows.add_widget(b)
            if files:
                seal = Label(text="", size_hint_y=None, height=dp(6))
                rows.add_widget(seal)
            for f in files:
                b = Button(text="PDF: " + f, halign="left", valign="middle",
                           size_hint_y=None, height=dp(42),
                           background_normal="", background_color=ACCENT,
                           color=(1, 1, 1, 1), font_size=dp(14), bold=True, shorten=True)
                b.bind(size=lambda w, *_: setattr(w, "text_size", (w.width - 10, None)))
                b.bind(on_release=lambda *a, ff=f, p=start_path: self._pick_file(p, ff))
                rows.add_widget(b)
            if len(files) > 300 or len(dirs) > 300:
                rows.add_widget(Label(text="(only first 300 shown)", color=MUTED,
                                      font_size=dp(11), size_hint_y=None, height=dp(28)))
            scroll.add_widget(rows)
            content.add_widget(scroll)

        modal = ModalView(size_hint=(0.96, 0.95), background_color=(0, 0, 0, 0.4))
        modal.add_widget(content)
        modal.open()
        self._pick_modal = modal

    def _close_picker(self):
        if self._pick_modal:
            self._pick_modal.dismiss()
            self._pick_modal = None

    def _go_up(self, stack):
        if len(stack) > 1:
            stack.pop()
            self._close_picker()
            self._show_picker(stack[-1], stack)
        else:
            self._close_picker()

    def _enter_dir(self, parent, name, stack):
        target = os.path.join(parent, name)
        stack.append(target)
        self._close_picker()
        self._show_picker(target, stack)

    def _pick_file(self, parent, name):
        p = os.path.join(parent, name)
        self.selected_file = p
        self.file_label.text = os.path.basename(p)
        self.status.text = "File ready. Press Convert."
        self._close_picker()

    def start_convert(self):
        if self.busy:
            return
        if not self.selected_file or not os.path.exists(self.selected_file):
            self.status.text = "First select a PDF file."
            return
        self.busy = True
        self.status.text = "Converting..."
        self.log_lines.clear()
        self.show_log("== Starting conversion ==")
        threading.Thread(target=self.worker, args=(self.selected_file,), daemon=True).start()

    def worker(self, pdf_path):
        try:
            eng = engine
            if eng is None:
                import engine as eng
            out = eng.convert_one(pdf_path, save_dir(), self.safe_log)
            if out:
                shared = self._publish_to_downloads(out)
                if shared:
                    self.safe_log("Done! Saved in Downloads as:")
                    self.safe_log("  %s" % shared)
                    self.q.put(("status", "Success - saved in Downloads"))
                else:
                    self.safe_log("Done! Converted. Choose save location:")
                    self.safe_log("  %s" % os.path.basename(out))
                    self.safe_log("(internal copy %s)" % out)
                    self.q.put(("saveask", out))
            else:
                self.q.put(("status", "Not a PDF file"))
        except Exception as exc:
            msg = str(exc)
            if "password" in msg.lower() or "encrypted" in msg.lower():
                self.safe_log("ERROR: file is password-protected. Remove the password first.")
                self.q.put(("status", "Password protected"))
            else:
                self.safe_log("ERROR: %s" % msg)
                self.q.put(("status", "Conversion failed"))

    def _publish_to_downloads(self, local_path):
        try:
            from jnius import autoclass
            from android import mActivity
            resolver = mActivity.getContentResolver()
            MediaStore = autoclass('android.provider.MediaStore')
            ContentValues = autoclass('android.content.ContentValues')
            name = os.path.basename(local_path)
            cv = ContentValues()
            cv.put("_display_name", name)
            cv.put("mime_type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
            try:
                cv.put("relative_path", "Download")
                cv.put("is_pending", 1)
            except Exception:
                pass
            try:
                collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
            except Exception:
                collection = MediaStore.Files.getContentUri("external")
            uri = resolver.insert(collection, cv)
            if uri is None:
                return None
            out = resolver.openOutputStream(uri)
            with open(local_path, "rb") as fh:
                while True:
                    chunk = fh.read(65536)
                    if not chunk:
                        break
                    out.write(chunk)
            out.flush()
            out.close()
            try:
                cv2 = ContentValues()
                cv2.put("is_pending", 0)
                resolver.update(uri, cv2, None, None)
            except Exception:
                pass
            return name
        except Exception:
            return None

    def _ask_save(self, internal_path):
        self._save_src = internal_path
        try:
            from jnius import autoclass
            Intent = autoclass('android.content.Intent')
            intent = Intent(Intent.ACTION_CREATE_DOCUMENT)
            intent.setType('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
            intent.putExtra(Intent.EXTRA_TITLE, os.path.basename(internal_path))
            intent.addCategory(Intent.CATEGORY_OPENABLE)
            intent.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            self._mActivity.startActivityForResult(intent, 7002)
            self.status.text = "Choose where to save..."
            return True
        except Exception:
            return False

    def safe_log(self, msg):
        self.q.put(("log", msg))

    def show_log(self, msg):
        self.log_lines.append(str(msg))
        self.log_box.text = "[size=12]" + "\n".join(self.log_lines) + "[/size]"
        self.log_box.text_size = (self.log_box.width, None)

    def drain_queue(self, dt=None):
        try:
            while True:
                item = self.q.get_nowait()
                if item[0] == "log":
                    self.show_log(item[1])
                elif item[0] == "status":
                    self.status.text = item[1]
                    self.busy = False
                elif item[0] == "saveask":
                    if not self._ask_save(item[1]):
                        self.status.text = "Saved internally"
                        self.busy = False
        except queue.Empty:
            pass


if __name__ == "__main__":
    PdfToExcelApp().run()
