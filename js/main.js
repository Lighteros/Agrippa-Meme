(() => {
  const canvas = document.getElementById("cosmos");
  const ctx = canvas.getContext("2d");
  const glow = document.querySelector(".cursor-glow");
  const toggle = document.getElementById("navToggle");
  const links = document.getElementById("navLinks");
  const copyBtn = document.getElementById("copyCa");
  const copyState = document.getElementById("copyState");
  const ca = "0xfa1824e750f9a5bc7d253342935471b8f2709d70";

  const stars = [];
  const motes = [];

  const resize = () => {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
  };

  const seed = () => {
    stars.length = 0;
    motes.length = 0;
    const count = Math.min(180, Math.floor((canvas.width * canvas.height) / 14000));
    for (let i = 0; i < count; i += 1) {
      stars.push({
        x: Math.random() * canvas.width,
        y: Math.random() * canvas.height,
        r: Math.random() * 1.3 + 0.2,
        a: Math.random() * 0.6 + 0.15,
        s: Math.random() * 0.25 + 0.05,
      });
    }
    for (let i = 0; i < 28; i += 1) {
      motes.push({
        x: Math.random() * canvas.width,
        y: Math.random() * canvas.height,
        r: Math.random() * 1.8 + 0.6,
        v: Math.random() * 0.18 + 0.04,
        drift: Math.random() * 0.4 - 0.2,
      });
    }
  };

  const draw = () => {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    stars.forEach((star) => {
      star.a += star.s * 0.02;
      ctx.beginPath();
      ctx.fillStyle = `rgba(240, 217, 160, ${0.18 + Math.abs(Math.sin(star.a)) * 0.55})`;
      ctx.arc(star.x, star.y, star.r, 0, Math.PI * 2);
      ctx.fill();
    });
    motes.forEach((mote) => {
      mote.y -= mote.v;
      mote.x += mote.drift * 0.15;
      if (mote.y < -10) {
        mote.y = canvas.height + 10;
        mote.x = Math.random() * canvas.width;
      }
      ctx.beginPath();
      ctx.fillStyle = "rgba(212, 176, 106, 0.35)";
      ctx.arc(mote.x, mote.y, mote.r, 0, Math.PI * 2);
      ctx.fill();
    });
    requestAnimationFrame(draw);
  };

  resize();
  seed();
  draw();
  window.addEventListener("resize", () => {
    resize();
    seed();
  });

  window.addEventListener("pointermove", (event) => {
    glow.style.transform = `translate(${event.clientX}px, ${event.clientY}px)`;
  });

  toggle.addEventListener("click", () => {
    links.classList.toggle("open");
  });

  links.querySelectorAll("a").forEach((link) => {
    link.addEventListener("click", () => links.classList.remove("open"));
  });

  copyBtn.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(ca);
      copyState.textContent = "Copied";
      copyBtn.classList.add("copied");
      setTimeout(() => {
        copyState.textContent = "Copy";
        copyBtn.classList.remove("copied");
      }, 1600);
    } catch (error) {
      copyState.textContent = "Select";
    }
  });

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("in-view");
        }
      });
    },
    { threshold: 0.16 }
  );

  document.querySelectorAll(".tablet, .step, .join-card, .chart-frame, .banner-shrine").forEach((node) => {
    observer.observe(node);
  });
})();
