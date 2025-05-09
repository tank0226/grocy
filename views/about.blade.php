@extends('layout.default')

@section('title', $__t('About Grocy'))

@section('content')
<div class="row">
	<div class="col text-center">
		<h2 class="title">@yield('title')</h2>

		<hr class="my-2">

		<ul class="nav nav-tabs grocy-tabs justify-content-center mt-3">
			<li class="nav-item">
				<a class="nav-link discrete-link active"
					id="system-info-tab"
					data-toggle="tab"
					href="#system-info">{{ $__t('System info') }}</a>
			</li>
			<li class="nav-item">
				<a class="nav-link discrete-link"
					id="changelog-tab"
					data-toggle="tab"
					href="#changelog">{{ $__t('Changelog') }}</a>
			</li>
		</ul>

		<div class="tab-content grocy-tabs mt-3">

			<div class="tab-pane show active"
				id="system-info">
				<div class="row">
					<div class="col-auto">
						<table class="table table-borderless table-responsive table-sm text-left">
							<tr>
								<td class="text-right">Version</td>
								<td><code>{{ $versionInfo->Version }}</code></td>
							</tr>
							<tr>
								<td class="text-right">Released on</td>
								<td><code>{{ $versionInfo->ReleaseDate }}</code> <time class="timeago timeago-contextual text-muted"
										datetime="{{ $versionInfo->ReleaseDate }}"></time></td>
							</tr>
							<tr>
								<td class="text-right">PHP Version</td>
								<td><code>{{ $systemInfo['php_version'] }}</code></td>
							</tr>
							<tr>
								<td class="text-right">SQLite Version</td>
								<td><code>{{ $systemInfo['sqlite_version'] }}</code></td>
							</tr>
							<tr>
								<td class="text-right">Database Version</td>
								<td><code>{{ $systemInfo['db_version'] }}</code></td>
							</tr>
							<tr>
								<td class="text-right">OS</td>
								<td><code>{{ $systemInfo['os'] }}</code></td>
							</tr>
							<tr>
								<td class="text-right">Client</td>
								<td><code>{{ $systemInfo['client'] }}</code></td>
							</tr>
						</table>
					</div>
				</div>

				<p class="border-top pt-3">
					{{ $__t('Do you find Grocy useful?') }}<br>
					<a class="btn btn-sm btn-primary text-white mt-1"
						href="https://grocy.info/#say-thanks"
						target="_blank">{{ $__t('Say thanks') }} <i class="fa-solid fa-heart"></i></a>
				</p>
			</div>

			<div class="tab-pane show"
				id="changelog">
				@php $Parsedown = new Parsedown(); @endphp
				@foreach($changelog['changelog_items'] as $changelogItem)
				<div class="card my-2">
					<div class="card-header">
						<a class="discrete-link"
							data-toggle="collapse-next"
							href="#">
							Version <span class="font-weight-bold">{{ $changelogItem['version'] }}</span><br>
							Released on <span class="font-weight-bold">{{ $changelogItem['release_date'] }}</span>
							<time class="timeago timeago-contextual text-muted"
								datetime="{{ $changelogItem['release_date'] }}"></time>
						</a>
					</div>
					<div class="collapse @if($changelogItem['release_number'] >= $changelog['newest_release_number'] - 4) show @endif">
						<div class="card-body text-left">
							{!! $Parsedown->text($changelogItem['body']) !!}
						</div>
					</div>
				</div>
				@endforeach
			</div>

		</div>

		<p class="small text-muted border-top pt-3">
			<a href="https://grocy.info"
				class="text-dark"
				target="_blank">Grocy</a> is a hobby project by
			<a href="https://berrnd.de"
				class="text-dark"
				target="_blank">Bernd Bestel</a><br>
			Created with passion since 2017<br>
			Life runs on Code<br>
		</p>
	</div>
</div>
@stop
