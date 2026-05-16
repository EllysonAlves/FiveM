const tireIds = { lf: 'tire-lf', rf: 'tire-rf', lr: 'tire-lr', rr: 'tire-rr' };

function stateFromTire(tire) {
  const temp = Number(tire?.temp ?? 30);
  const wear = Number(tire?.wear ?? 0);
  if (wear >= 72 || temp >= 130) return 'critical';
  if (temp >= 110) return 'overheated';
  if (temp >= 95) return 'hot';
  if (temp >= 70) return 'ideal';
  if (temp >= 50) return 'warming';
  return 'cold';
}

function stateFromBrake(temp) {
  const value = Number(temp || 30);
  if (value >= 700) return 'critical';
  if (value >= 520) return 'overheated';
  if (value >= 180) return 'ideal';
  if (value >= 80) return 'warming';
  return 'cold';
}

function setState(el, state) {
  if (!el) return;
  el.className = el.className.replace(/\b(cold|warming|ideal|hot|overheated|critical)\b/g, '').trim();
  el.classList.add(state);
}

function createNitroAudio() {
  let ctx;
  let master;
  let airFilter;
  let bodyFilter;
  let airGain;
  let bodyGain;
  let noiseSource;

  function createPressureNoiseBuffer(context) {
    const buffer = context.createBuffer(1, context.sampleRate * 2, context.sampleRate);
    const data = buffer.getChannelData(0);
    let smoothed = 0;
    for (let i = 0; i < data.length; i++) {
      smoothed = (smoothed * 0.985) + ((Math.random() * 2 - 1) * 0.015);
      data[i] = smoothed * 3.1;
    }
    return buffer;
  }

  function ensure() {
    if (ctx) return;
    ctx = new (window.AudioContext || window.webkitAudioContext)();
    master = ctx.createGain();
    master.gain.value = 0;
    master.connect(ctx.destination);

    noiseSource = ctx.createBufferSource();
    noiseSource.buffer = createPressureNoiseBuffer(ctx);
    noiseSource.loop = true;

    airFilter = ctx.createBiquadFilter();
    airFilter.type = 'bandpass';
    airFilter.frequency.value = 1250;
    airFilter.Q.value = 0.55;
    airGain = ctx.createGain();
    airGain.gain.value = 0.28;

    bodyFilter = ctx.createBiquadFilter();
    bodyFilter.type = 'lowpass';
    bodyFilter.frequency.value = 260;
    bodyFilter.Q.value = 0.45;
    bodyGain = ctx.createGain();
    bodyGain.gain.value = 0.13;

    noiseSource.connect(airFilter);
    airFilter.connect(airGain);
    airGain.connect(master);
    noiseSource.connect(bodyFilter);
    bodyFilter.connect(bodyGain);
    bodyGain.connect(master);
    noiseSource.start();
  }

  function setActive(nextActive, mode = 'balanced') {
    ensure();
    if (ctx.state === 'suspended') ctx.resume();
    const now = ctx.currentTime;
    const active = !!nextActive;
    const volume = active ? (mode === 'power' ? 0.28 : mode === 'eco' ? 0.18 : 0.23) : 0.0001;
    const airFreq = mode === 'power' ? 1480 : mode === 'eco' ? 980 : 1220;
    const bodyFreq = mode === 'power' ? 310 : mode === 'eco' ? 210 : 260;
    airFilter.frequency.setTargetAtTime(airFreq, now, 0.10);
    bodyFilter.frequency.setTargetAtTime(bodyFreq, now, 0.12);
    master.gain.cancelScheduledValues(now);
    master.gain.setTargetAtTime(volume, now, active ? 0.08 : 0.18);
  }

  return { setActive };
}

const nitroAudio = createNitroAudio();

window.addEventListener('message', (event) => {
  const message = event.data || {};
  if (message.action === 'thermal') {
    const hud = document.getElementById('thermal-hud');
    hud?.classList.toggle('hidden', !message.show);
    const tires = message.tires || {};
    Object.entries(tireIds).forEach(([key, id]) => setState(document.getElementById(id), stateFromTire(tires[key])));
    setState(document.getElementById('brake'), stateFromBrake(message.brakeTemp));
  }

  if (message.action === 'nitroSound') {
    nitroAudio.setActive(message.active, message.mode);
  }
});
