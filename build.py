import base64, re
old = open('daynest.html').read()
script = old[old.index('<script>'):]
reps = [
 ("const WD_FULL =", "const WD_SHORT = ['Пн','Вт','Ср','Чт','Пт','Сб','Нд'];\n  const WD_FULL ="),
 ("$('#dayTitle').textContent = isToday ? 'Завдання на сьогодні' : (state.selected === keyOf(addDays(today,1)) ? 'Завдання на завтра' : 'Завдання на день');",
  "$('#dayTitle').textContent = isToday ? 'Сьогоднішні справи' : (state.selected === keyOf(addDays(today,1)) ? 'Справи на завтра' : 'Справи на день');"),
 ("$('#dayDate').textContent = `${WD_FULL[wdIndex(d)]}, ${longDate(d)}`;",
  "$('#dayDate').textContent = isToday ? longDate(d) : `${WD_FULL[wdIndex(d)]}, ${longDate(d)}`;"),
 ("b.innerHTML = `<span>${MONTH_SHORT[x.getMonth()]}</span><b>${x.getDate()}</b>`;",
  "b.innerHTML = `<span>${WD_SHORT[i]}</span><b>${x.getDate()}</b>`;"),
 ('stroke="#fcedc6" stroke-width="2.2"', 'stroke="#fdf4e3" stroke-width="2.4"'),
 ('<svg width="12" height="12" viewBox="0 0 12 12"', '<svg width="15" height="15" viewBox="0 0 12 12"'),
 ("<em class=\"n\" style=\"font-style:normal\">", "<em class=\"n\">"),
 ("$('#catBtn').addEventListener('click', () => openSheet(null));",
  "$('#catBtn').addEventListener('click', e => { const b = e.currentTarget; b.classList.remove('tapped'); void b.offsetWidth; b.classList.add('tapped'); setTimeout(() => openSheet(null), 180); });"),
]
for a,b in reps:
    if b in script: continue
    if a not in script: continue
    script = script.replace(a,b)
src = open('src.html').read()
for n in ['welcome','sun','catscene','paw','calendar','catwink']:
    data = base64.b64encode(open(f'assets/{n}.webp','rb').read()).decode()
    src = src.replace('{{%s}}'%n, 'data:image/webp;base64,'+data)
assert '{{' not in src
open('daynest.html','w').write(src + '\n' + script)
print(len(src+script))
