import React from 'react';
import {
  Tab, Row, Col, Nav,
} from 'react-bootstrap';
import PropTypes from 'prop-types';

const style = {
  date: {
    fontFamily: 'Inconsolata,monospace',
    fontSie: '10pt',
    whiteSpace: 'nowrap',
  },
  location: {
    fontWeight: 'bold',
    fontSie: '10pt',
    whiteSpace: 'nowrap',
  },
};

class ControlledTabs extends React.Component {
  constructor(props) {
    super(props);

    const { jobs } = this.props;

    this.state = {
      key: jobs[0].company,
    };
  }

  render() {
    const { jobs } = this.props;
    const { key } = this.state;
    return (
      <Tab.Container defaultActiveKey={key}>
        <Row>
          <Col sm={3} style={{ marginRight: '10px' }}>
            <Nav variant="pills" className="flex-column">
              { jobs.map(job => (
                <Nav.Item key={job.company}>
                  <Nav.Link eventKey={job.company}>
                    {job.company}
                  </Nav.Link>
                </Nav.Item>
              ))}
            </Nav>
          </Col>
          <Col sm={7} style={{ marginTop: '10px' }}>
            <Tab.Content>
              { jobs.map(job => (
                <Tab.Pane key={job.company} eventKey={job.company}>
                  <Row>
                    <Col style={style.location}>
                      {'📍 '}
                      {job.location}
                    </Col>
                    <Col md={7} style={style.date}>
                      {'📅 '}
                      {job.date}
                    </Col>
                  </Row>
                  <ul>
                    {job.items.map(item => <li key={item}>{item}</li>)}
                  </ul>
                </Tab.Pane>
              ))}
            </Tab.Content>
          </Col>
        </Row>
      </Tab.Container>
    );
  }
}

ControlledTabs.propTypes = {
  jobs: PropTypes.arrayOf(Object).isRequired,
};

export default ControlledTabs;