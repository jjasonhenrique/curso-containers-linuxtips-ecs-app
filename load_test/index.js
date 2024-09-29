import http from 'k6/http';
import { sleep } from 'k6';
export const options = {
  vus: 50,
  duration: '300000s',
};

const params = {
    headers: {
        'Content-Type': 'application/json',
        'Host': 'chip.linuxtips.demo'
    },
};

export default function () {
  http.get('http://containers-linuxtips-ingress-1932202900.us-east-1.elb.amazonaws.com/system', params);
  sleep(1);
}