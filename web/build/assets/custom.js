(function() {
  var res = window.GetParentResourceName ? window.GetParentResourceName() : "juddlie_appearance";
  var tattoos = [];
  var highlighted = null;
  var keysHeld = {};

  function post(action, data) {
    return fetch("https://" + res + "/" + action, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data || {})
    });
  }

  window.addEventListener("message", function(ev) {
    if (!ev.data || !ev.data.action) return;
    if (ev.data.action === "tattooList" && ev.data.data && ev.data.data.tattoos) {
      tattoos = ev.data.data.tattoos;
      clearHighlight();
    }
    if (ev.data.action === "setVisible" && ev.data.data && !ev.data.data.visible) {
      keysHeld = {};
      tattoos = [];
      clearHighlight();
    }
  });

  function clearHighlight() {
    if (highlighted) {
      highlighted.style.outline = "";
      highlighted.style.backgroundColor = "";
      highlighted = null;
      post("appearance:clearPreview");
    }
  }

  function getTattooItem(el) {
    var node = el;
    while (node && node !== document.body) {
      if (node.querySelector && node.querySelector("button") && node.children.length >= 3) {
        var cs = window.getComputedStyle(node);
        if (cs.display === "flex" && cs.alignItems === "center") {
          return node;
        }
      }
      node = node.parentElement;
    }
    return null;
  }

  function extractTexts(item) {
    var texts = [];
    for (var i = 0; i < item.children.length; i++) {
      var ch = item.children[i];
      if (ch.tagName !== "BUTTON" && ch.tagName !== "button") {
        texts.push(ch.textContent.trim());
      }
    }
    return texts;
  }

  function findTattoo(label, collection) {
    for (var i = 0; i < tattoos.length; i++) {
      if (tattoos[i].label === label && tattoos[i].collection === collection) return tattoos[i];
    }
    for (var i = 0; i < tattoos.length; i++) {
      if (tattoos[i].label === label) return tattoos[i];
    }
    return null;
  }

  document.addEventListener("click", function(e) {
    if (!tattoos.length) return;
    if (e.target.tagName === "BUTTON" || e.target.closest("button")) return;

    var item = getTattooItem(e.target);
    if (!item) return;

    var texts = extractTexts(item);
    if (texts.length < 2) return;

    var t = findTattoo(texts[0], texts[1]);
    if (!t) return;

    clearHighlight();
    highlighted = item;
    item.style.outline = "1px solid rgba(59, 130, 246, 0.8)";
    item.style.backgroundColor = "rgba(59, 130, 246, 0.15)";

    post("appearance:previewTattoo", { collection: t.collection, overlay: t.overlay });
  });

  document.addEventListener("keydown", function(e) {
    if (e.target.tagName === "INPUT" || e.target.tagName === "TEXTAREA" || e.target.isContentEditable) return;
    var k = e.key.toLowerCase();
    if ((k === "a" || k === "d" || k === "w" || k === "s") && !keysHeld[k]) {
      keysHeld[k] = true;
      post("appearance:keyPress", { key: k, pressed: true });
    }
  });

  document.addEventListener("keyup", function(e) {
    var k = e.key.toLowerCase();
    if (k === "a" || k === "d" || k === "w" || k === "s") {
      keysHeld[k] = false;
      post("appearance:keyPress", { key: k, pressed: false });
    }
  });

  function isScrollable(el) {
    while (el) {
      var style = window.getComputedStyle(el);
      if (style.overflowY === 'auto' || style.overflowY === 'scroll' || style.overflow === 'auto' || style.overflow === 'scroll') return true;
      el = el.parentElement;
    }
    return false;
  }

  document.addEventListener("wheel", function(e) {
    if (e.target.closest('button') || e.target.closest('input') || e.target.closest('select') || e.target.closest('textarea') || isScrollable(e.target)) return;
    e.preventDefault();
    var delta = e.deltaY > 0 ? 1 : -1;
    post("appearance:adjustFov", { delta: delta });
  });
})();
