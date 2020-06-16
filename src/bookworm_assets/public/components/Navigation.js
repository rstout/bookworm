import React from 'react';
import { NavLink } from 'react-router-dom';

const Navigation = () => {
  return (
    <nav className="main-nav">
      <ul>
        <li><NavLink to="/subscriptions">Subscriptions</NavLink></li>
        <li><NavLink to="/discover">Discover</NavLink></li>
        <li><NavLink to="/publish">Publish</NavLink></li>
      </ul>
    </nav>
  );
}

export default Navigation;
