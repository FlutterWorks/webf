import React, {useEffect, useRef, useState} from 'react';
import clsx from 'clsx';

import './styles.css';
import Link from "@docusaurus/Link";

type ReactFunc = () => React.JSX.Element;

type FeatureItem = {
  title: string;
  img: string | ReactFunc;
  description: string;
  btnLink: string;
  btnText: string;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'Backward compatible with web browsers',
    img: CrossPlatformLabels,
    description: "WebF provides a subset of the W3C/WHATWG standard HTML/CSS and ECMAScript 2020 JavaScript support. WebF gives you the DOM API, Window, Document, and other Web APIs, and yields the same results and behavior as web browsers.",
    btnLink: '/docs/tutorials/guides-for-web-developer/overview',
    btnText: 'Learn More'
  },
  {
    title: 'High Performance',
    img: '',
    description: 'Execute bytecode with optimized QuickJS engine, and render HTML/CSS in the same context as Flutter apps, saving 50% load times compared to WebView.',
    btnLink: '/',
    btnText: 'Learn More'
  },
  {
    title: 'Enhance your web with client-side technologies',
    img: '',
    description: 'Embed anything supported by Flutter in WebF: combine pre-trained AI models with web apps, use hardware-accelerated video players, or integrate Unity game engines with AR/VR/MR apps in your web pages at full speed.',
    btnLink: '/',
    btnText: 'Learn more'
  },
  {
    title: 'Smaller Bundle Size',
    img: '',
    description: 'WebF only takes up 4-5 MB of disk space if you already have Flutter integrated.',
    btnLink: '/',
    btnText: 'Have a Try'
  },
  {
    title: 'One Runtime for All Platforms',
    img: '',
    description: 'All HTML/CSS and JavaScript support is self-contained. All of your UI is rendered by Flutter, giving you 100% consistency across mobile and desktop platforms with no external WebView required, thereby eliminating concerns about browser compatibility',
    btnLink: '/',
    btnText: 'Learn more'
  },
  {
    title: 'Inspect your WebF apps with Chrome Inspector',
    description: 'Utilize your favorite web frameworks, build tools, and Chrome DevTools to develop, debug, and deploy your apps.',
    btnLink: '/',
    img: '/img/devtools.png',
    btnText: 'Learn More'
  },
  {
    title: 'Native User experience',
    img: '',
    description: 'Seamlessly integrate Flutter navigation with the web history API or add pull-to-refresh gestures to your web apps. This makes your WebF more like native apps, not just a web app.',
    btnLink: '/',
    btnText: 'Learn more'
  }
];

function CrossPlatformLabels() {
  const img = useRef<HTMLImageElement>(null);
  const title = useRef<HTMLSpanElement>(null);
  const [visibleText, setVisible] = useState(false);
  const [titleOffset, setTitleOffset] = useState([0, 0]);

  useEffect(() => {
    img.current.onload = () => {
      setVisible(true);

      const titleWidth = title.current.offsetWidth;

      setTitleOffset([
        0,
        img.current.clientWidth / 2 - titleWidth / 2 + (img.current.clientWidth * 0.05)
      ]);
    };
  }, []);


  return <div className={'cross-platform-container'}>
    <img ref={img} src={'/img/cross-platform.png'}></img>
    <span ref={title} style={{display: visibleText ? 'block' : 'none', top: `${titleOffset[0]}px`, left: `${titleOffset[1]}px`}} className={"cross-img-title"}>Your App</span>
  </div>;
}

function Feature(props: FeatureItem & {idx: number}) {
  return (
    <div className={"feature " + (props.idx % 2 == 0 ? '' : 'reverse')}>
      <div className={"feature_wrapper"}>
        <h2 className="title">{props.title}</h2>
        <p>{props.description}</p>
        { props.img ? (typeof props.img === 'string' ? <img src={props.img} alt={'IMG'}/> : props.img()) : ''}
        <div className={"button_wrapper"}>
          <Link className="button_item btn_default" to={props.btnLink}>{props.btnText}</Link>
        </div>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): JSX.Element {
  return (
    <section className="feature_container">
      {FeatureList.map((props, idx) => (
        <Feature key={idx} {...props} idx={idx} />
      ))}
    </section>
  );
}
